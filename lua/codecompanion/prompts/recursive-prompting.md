---
name: Recursive Prompting
interaction: chat
description: One prompt = one answer. Recursive prompts = systems that think in loops.
opts:
  alias: recursive_prompting
  auto_submit: false
  is_slash_cmd: false
  stop_context_insertion: true
  user_prompt: true
---

## user

Iteration 1: [$ARGUMENTS]

Iteration 2: Review the solution from Iteration 1. Identify gaps and improve.

Iteration 3: Review Iteration 2. Focus on [specific aspect]. Refine further.

Final: Synthesize all iterations into the best version.
