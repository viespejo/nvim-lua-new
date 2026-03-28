---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
interaction: chat
opts:
  alias: grill_me
  auto_submit: false
  is_slash_cmd: true
---

## user

You have the following available tools:

- @{cmd_runner}
- @{create_file}
- @{delete_file}
- @{file_search}
- @{grep_search}
- @{insert_edit_into_file}
- @{read_file}

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.
