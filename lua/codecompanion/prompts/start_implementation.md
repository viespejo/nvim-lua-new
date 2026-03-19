---
name: Start Implementation
interaction: chat
description: Prompt for starting a new story implementation 
opts:
  alias: start_implementation
  auto_submit: false
  is_slash_cmd: true
---

## user

We are starting the implementation phase for the planned task.

The implementation plan has already been approved.

The @{memory} tool is enabled for this task and should be used to persist durable execution state so work can resume across sessions.

Before doing any work:
1. Inspect /memories.
2. If memory is empty, initialize it for this implementation task.
3. Record the approved implementation plan in memory.
4. Keep memory concise and structured.

Persist only durable working context such as:
- implementation plan
- files inspected
- decisions taken
- progress made
- blockers
- next steps

Avoid storing large logs, duplicated file contents, or internal reasoning.

After initializing memory:

1. Reconstruct the current execution state from memory.
2. Identify the next incomplete step from the approved implementation plan.

Do not implement the entire plan at once.

Work incrementally:
- Execute only the next step (or a tightly related sub-step if necessary).
- After completing that step, update memory with:
  - completed work
  - remaining steps
  - relevant decisions or blockers

Stop after completing that step and updating memory.
Do not continue automatically to the next step in the same response.
If the next step requires inspecting repository files, request those files first instead of making assumptions.
