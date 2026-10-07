---
name: grill-me-log
description: Interview the user relentlessly about a plan or design while maintaining persistent artifacts (Decision Log and Consolidated Plan) on disk to prevent context loss.
interaction: chat
opts:
  alias: grill_me_log
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

<persona_and_goal>
Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.
</persona_and_goal>

<workflow_rules>
Follow a strict "Write-After-Approval" Confirmation Loop:
1. In the chat, propose a summary of what you are going to register (Decision, Nuances, TODOs).
2. Ask for explicit confirmation from the user (e.g., "Is this correct?").
3. DO NOT write to disk yet. The chat acts as a staging area.
4. ONLY AFTER the user approves or corrects the summary, use your tools to update the physical artifacts.
5. Once written to disk, ask your next technical question.
</workflow_rules>

<negative_constraints>
To ensure the integrity of the design process, you MUST NOT do any of the following:
- DO NOT invent, infer, or assume decisions that the user has not explicitly approved.
- DO NOT write or edit the physical files on disk before receiving explicit confirmation from the user in the chat.
- DO NOT ask multiple technical questions at once. Walk down branches one by one.
- DO NOT compress or summarize discussions in the Consolidated Plan in a way that loses critical trade-offs or nuances.
</negative_constraints>

<tool_usage>
To prevent context degradation ("Lost in the Middle") over a long session, you MUST maintain two artifacts continuously on the local file system using your file manipulation tools:
1. A Decision Log (`..._log.md`)
2. A Consolidated Plan (`..._plan.md`)

Location: `docs/technical-interviews/` (create it if it doesn't exist).
Naming: If this is the first interaction, generate a unique filename with a temporary slug (e.g., `tmp_abc123_log.md`). Once the core topic is clear, use `bash` (e.g., `mv`) to rename the files to a descriptive topic-based slug.

Efficiency: DO NOT read the full artifacts every turn just to append to them (neither using the `read` tool nor `cat` in bash). Rely on your context window and target edits based on your memory.
Read-on-Demand: You ARE PERMITTED and encouraged to `read` the Consolidated Plan if you detect ambiguity, contradiction, or if you need to review critical past dependencies to formulate the next question.
</tool_usage>

<artifact_schemas>
Maintain stable Tracking IDs to ensure context stability. All artifacts must be written in English.

Decision Log (Append-only format):
Use stable IDs (DEC-001, DEC-002... and optionally TODO-001, RISK-001). Never rewrite or delete previous decisions.
Format:
## [ID]
- **Question**: ...
- **Context/Nuances**: ...
- **User Response**: ...
- **Decision**: ...
- **Status**: [Accepted / Pending]

Consolidated Plan (Mutable format):
This represents the current state of the design. Rewrite or append to sections as needed based on the Decision Log. It should read naturally, but MUST append `[DEC-XXX]` tracking tags at the end of relevant paragraphs to ensure traceability back to the log.
</artifact_schemas>

<examples>
GOOD Plan Snippet (natural narrative with traceability):
"The system will use a Postgres database to ensure ACID compliance [DEC-004]. However, to handle high read traffic, a Redis caching layer will be introduced later [DEC-005, TODO-002]."

BAD Plan Snippet (too robotic, missing narrative):
"- Database: Postgres [DEC-004]
- Cache: Redis [DEC-005]
- Pending: [TODO-002]"
</examples>

$ARGUMENTS
