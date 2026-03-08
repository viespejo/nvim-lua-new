---
name: ToT - Tree of Thoughts
interaction: chat
description: Linear thinking gets linear results. ToT explores multiple reasoning paths simultaneously.
opts:
  alias: tot
  auto_submit: false
  is_slash_cmd: false
  stop_context_insertion: true
  user_prompt: true
---

## user

Explore 3 different approaches to solve: [$ARGUMENTS].

For each approach:
- Break down the reasoning steps
- Evaluate pros and cons
- Assign a confidence score

Then recommend the best approach with justification.
