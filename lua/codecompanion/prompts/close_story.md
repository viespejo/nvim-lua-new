---
name: Close Story
interaction: chat
description: Generate a commit message for closing a story implementation
opts:
  alias: close_story
  auto_submit: false
  is_slash_cmd: true
---

## user

We are finishing work on the current story.

Please analyze the implemented changes and update the project ledger.

Relevant document:

docs/implementation-ledger.md

Tasks:

1. Identify the key implementation changes introduced by this story.
2. Extract any important implementation decisions that should be recorded.
3. Identify follow-up work, limitations, or technical debt introduced during implementation.
4. Propose a new entry for the implementation ledger.

Follow the existing ledger structure:

- Context
- Changes
- Decisions
- Follow-ups
- Technical Debt (optional)

Keep the entry concise and focused on durable implementation knowledge.

Do not include large code snippets or repeat the story description.
