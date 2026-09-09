import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { buildArgs, readEvents, run } from './reviewer.mjs';

const request = { provider: 'codex', model: 'frontier-test', effort: 'high', cwd: '.', promptFile: 'brief.md', roundId: 'r1' };
test('both providers explicitly preserve medium/high on exact-session resume', () => {
  for (const provider of ['codex', 'claude']) for (const effort of ['medium', 'high']) {
    const args = buildArgs({ ...request, provider, effort }, 'reviewer-session');
    assert.ok(args.includes('reviewer-session'));
    assert.ok(args.some(v => v.includes(effort)));
    assert.ok(!args.includes('--last'));
    assert.ok(!args.some(v => /bypass/i.test(v)));
  }
  for (const effort of ['low', 'ultra', 'max', 'xhigh']) assert.throws(() => buildArgs({ ...request, effort }));
});
test('a partial or failed turn is not a completed review', () => {
  assert.equal(readEvents('codex', JSON.stringify({ type: 'item.completed', item: { type: 'agent_message', text: 'Looks fine' } })).completed, false);
  assert.equal(readEvents('claude', JSON.stringify({ type: 'result', subtype: 'error_max_turns', result: 'Looks fine' })).failed, true);
});
test('real child transport preserves prompts, resumes and rejects duplicate rounds/model changes', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'babysit-pr-test-'));
  const cli = join(dir, 'fake.js');
  writeFileSync(cli, `let p='';process.stdin.on('data',d=>p+=d);process.stdin.on('end',()=>{console.log(JSON.stringify({type:'thread.started',thread_id:'test-session'}));console.log(JSON.stringify({type:'item.completed',item:{type:'agent_message',text:p}}));console.log(JSON.stringify({type:'turn.completed'}));});`);
  const promptFile = join(dir, 'brief.md');
  writeFileSync(promptFile, 'Literal $() `command` "quotes"\nSecond line');
  const input = join(dir, 'request.json');
  const r = { ...request, cwd: dir, promptFile, cli };
  writeFileSync(input, JSON.stringify(r));
  const session = join(dir, 'session');
  await run(input, session, true);
  assert.equal(existsSync(session), false);
  const result = await run(input, session);
  assert.equal(result.status, 'returned');
  assert.ok(readFileSync(result.result, 'utf8').endsWith(readFileSync(promptFile, 'utf8')));
  assert.equal((await run(input, session, true)).resumes, 'test-session');
  await assert.rejects(run(input, session));
  writeFileSync(input, JSON.stringify({ ...r, model: 'changed' }));
  await assert.rejects(run(input, session), /fresh session/);
});
test('Claude results and session IDs survive a real subprocess; failed turns retain evidence', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'babysit-pr-claude-test-'));
  const cli = join(dir, 'fake.js');
  writeFileSync(cli, `process.stdin.resume();process.stdin.on('end',()=>console.log(JSON.stringify({type:'result',subtype:'success',session_id:'claude-test-session',result:'Verdict: clear'})));`);
  const promptFile = join(dir, 'brief.md');
  writeFileSync(promptFile, 'Review this fixture.');
  const input = join(dir, 'request.json');
  const r = { ...request, provider: 'claude', cwd: dir, promptFile, cli };
  writeFileSync(input, JSON.stringify(r));
  const session = join(dir, 'session');
  assert.equal((await run(input, session)).sessionId, 'claude-test-session');
  assert.ok((await run(input, session, true)).args.includes('--resume'));
  writeFileSync(cli, `process.stdin.resume();process.stdin.on('end',()=>console.log(JSON.stringify({type:'result',subtype:'error_max_turns',session_id:'claude-test-session',is_error:true,result:'Incomplete'})));`);
  writeFileSync(input, JSON.stringify({ ...r, roundId: 'r2' }));
  await assert.rejects(run(input, session), /failed/);
  assert.equal(JSON.parse(readFileSync(join(session, 'r2', 'status.json'))).status, 'failed');
  assert.equal(existsSync(join(session, 'active.lock')), false);
  writeFileSync(join(session, 'active.lock'), 'another run');
  await assert.rejects(run(input, session), /locked/);
});
