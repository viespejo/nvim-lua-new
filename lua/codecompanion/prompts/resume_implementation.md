---
name: Resume Implementation
interaction: chat
description: Prompt for resuming an existing story implementation
opts:
  alias: resume_implementation
  auto_submit: false
  is_slash_cmd: true
---

## user

We are resuming an implementation session.

The @{memory} tool contains the execution state from previous sessions.

Before doing any work:
1. Inspect /memories.
2. Reconstruct the current implementation state from memory.
3. Summarize:
   - the approved implementation plan
   - work already completed
   - remaining steps
   - blockers, if any

Then continue the implementation from where it stopped.

Do not restart analysis or re-plan the task unless memory clearly shows that the plan is incomplete or invalid.
