# GargAgents.md

- Neatly organized folder structure → plan, requirements, codebase, test-cases, history, logs
    
    ```
    my-app/
      agents.md
      README.md
      plan/
        00-overview.md
        10-architecture.md
        20-roadmap.md
        30-decisions.md
      requirements/
        prd.md
        constraints.md
      design/
        ux-flows.md
        wireframes/
        api-contracts.md
        data-model.md
      prompts/
        task-templates/
          bugfix.md
          feature.md
          refactor.md
          test-plan.md
        snippets/
          code-review-checklist.md
          release-checklist.md
      codebase/
        apps/            # (optional) monorepo-style
        packages/        # (optional) shared libs
        src/             # (single-app style; use one of these patterns, not both)
        public/
        config/
      tests/
        unit/
        integration/
        e2e/
        test-cases.md
      scripts/
        setup.sh
        lint.sh
        test.sh
        build.sh
        dev.sh
      data/
        seeds/
        migrations/
        samples/
      ops/
        runbooks.md
        monitoring.md
      logs/
        agent-run-log.md
        decisions-log.md
        changelog.md
      history/
        2026-02-28/
          01-plan-v1.md
          02-review-v1.md
          03-plan-v2.md
          04-review-v2.md
          05-plan-v3.md
          06-review-v3.md
          07-implementation-notes.md
          08-test-results.md
        learnings.md
    ```
    
    ---
    
    1. **One source of truth for requirements**: only `/requirements/*` is authoritative.
    2. **Tests live outside code** (in `/tests`) so the agent won’t mix concerns.
    3. **Scripts are mandatory**: any repeated command becomes a script.
    4. **Logs are append-only**: never rewrite history; agents learn from it.
    5. **Keep `prompts/` small but powerful**: a few templates beat 50 random prompts.
    
    ---
    
- Use [Agents.md](http://Agents.md) as master custom instructions for the folder
- All instructions and requirements given as input to you as Markdown files are stored in the `requirements/` folder.
- The agent saves all work history in a `history/` folder, regularly compacts it, and maintains a separate append-only markdown log for a complete chronological record.
- [Learnings.md](http://learnings.md/): create a file that logs mistakes and extracted learnings in the history folder whenever agents commit mistakes and realize it
- Agent always plans first: a detailed, no-code plan outlining each step in **what → why → how** format. It shares the plan with a Reviewer for improvements, incorporates feedback, and repeats this review loop three times before marking the plan ready. All iterations are saved in the master history log.
- It always operates with two agents: a Worker and an Expert Reviewer. The Worker shares its plan with the Reviewer before implementation for iterative improvements. After implementation, it asks the Reviewer to validate correctness.
- Worker always writes test cases before implementation, runs them after coding, and iteratively fixes errors until all tests pass. If stuck, it escalates to the Expert Reviewer for analysis and guidance.
- Runs in a structured loop: **plan → refine plan** (asks up to 4 clarifying questions) → split into parallel, dependency-free workstreams where possible (otherwise keep as a single sequential plan) → create tickets → write test cases for all tickets first → spin up sub-agents to execute parallel workstreams and assign tickets → monitor completion status → run full test suite to verify end-to-end completion.