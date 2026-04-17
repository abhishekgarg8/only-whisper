# Agents.md - Master Custom Instructions

## Core Principles

1. **One source of truth for requirements**: only `/requirements/*` is authoritative.
2. **Tests live outside code** (in `/tests`) so the agent won't mix concerns.
3. **Scripts are mandatory**: any repeated command becomes a script.
4. **Logs are append-only**: never rewrite history; agents learn from it.
5. **Keep `prompts/` small but powerful**: a few templates beat 50 random prompts.

## Workflow

### Planning Phase
- Agent always plans first: a detailed, no-code plan outlining each step in **what → why → how** format
- Plans are saved in `/plan/` directory
- Plans are shared with a Reviewer for improvements
- Incorporate feedback and repeat review loop **three times** before marking plan ready
- All iterations are saved in the master history log at `/history/YYYY-MM-DD/`

### Two-Agent System
- Operates with two agents: **Worker** and **Expert Reviewer**
- Worker shares plan with Reviewer before implementation for iterative improvements
- After implementation, Worker asks Reviewer to validate correctness

### Test-Driven Development
- Worker always writes test cases **before implementation** in `/tests/test-cases.md`
- Runs tests after coding
- Iteratively fixes errors until all tests pass
- If stuck, escalates to Expert Reviewer for analysis and guidance

### Execution Loop
1. **Plan** → Refine plan (ask up to 4 clarifying questions)
2. Split into **parallel, dependency-free workstreams** where possible (otherwise keep as single sequential plan)
3. Create tickets for workstreams
4. Write test cases for all tickets first
5. Spin up sub-agents to execute parallel workstreams and assign tickets
6. Monitor completion status
7. Run full test suite to verify end-to-end completion

## History & Learning

### History Logging
- Create dated folders in `/history/YYYY-MM-DD/` for each work session
- Save all plan iterations, reviews, and implementation notes
- Example structure:
  ```
  history/2026-02-28/
    01-plan-v1.md
    02-review-v1.md
    03-plan-v2.md
    04-review-v2.md
    05-plan-v3.md
    06-review-v3.md
    07-implementation-notes.md
    08-test-results.md
  ```

### Learnings.md
- Create `/history/learnings.md` to log mistakes and extracted learnings
- Append whenever agents commit mistakes and realize it
- Format: Date, Mistake, Root Cause, Learning, Prevention

## File Organization Rules

- All instructions and requirements given as input are stored in `/requirements/` folder
- All work history saved in `/history/` folder with regular compaction
- Maintain separate append-only markdown log in `/logs/` for complete chronological record
- Never rewrite history - always append
