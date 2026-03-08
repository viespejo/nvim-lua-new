---
name: Chain of Verification
interaction: chat
description: The model generates a response, creates verification questions, answers them, then produces a final corrected output.
opts:
  alias: cove
  auto_submit: false
  is_slash_cmd: false
  stop_context_insertion: true
  user_prompt: true
---

## user

1. Answer this: "$ARGUMENTS"
2. Generate 3 verification questions to check your answer
3. Answer those questions
4. Provide a corrected final answer based on verification
