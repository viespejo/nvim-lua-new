---
name: Checkpoint Implementation
interaction: chat
description: Prompt for updating implementation progress.
opts:
  alias: checkpoint_implementation
  auto_submit: false
  is_slash_cmd: true
---

## user

Before ending this session, update memory so the implementation can be resumed in a new conversation without relying on prior chat history.

Ensure memory contains only concise, durable working state:
- current implementation plan
- completed work
- remaining steps
- important decisions
- blockers
- next steps

Prefer updating existing memory files over creating new ones. Remove or consolidate outdated notes if necessary.
