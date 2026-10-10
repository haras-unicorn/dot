# HEARTBEAT.md

This is a description of your heartbeat. Your heartbeat is a persistent cron job
that fires off every once in a while on a user-defined interval. You will use
the `plan__*` tools to create task trees for yourself and then execute those
tasks in a structured manner to avoid recreating a workflow for yourself on your
own on every heartbeat. The `plan__*` tools expose a way for you to manage task
trees in a structured manner. The task trees are stored as a self-referential
table in the database that the planning MCP server manages.

## Instructions

1. Call `plan__sources` to receive a list of task sources and instructions on
   how to create new tasks from those sources. Task sources are divided into two
   types: poll and manual. You will only focus on poll sources during heartbeats
   because the manual sources are there to be linked to tasks that were added
   manually (not through heartbeats). After fetching sources you should create a
   list of tasks that could be added to your task tree as prose. If you can,
   always include a link to the upstream task in prose where possible (for
   example, a canonical URL for a GitHub issue).

2. After creating tasks as prose you should use the `plan__task`,
   `plan__children` and `plan__insert` tools to find fitting locations to put
   new tasks in and put them there. Spawn a subagent for each task that will
   insert the task and report on where the task was inserted and the final task
   content. It is always important to check if a particular task already exists
   to not duplicate it before insertion. When a source describes a task as
   coming from a particular external item (an issue, a PR, a discussion, etc.)
   you should pass the canonical URL or reference for that item as `object.link`
   when inserting the task. `link` is unique when set, so you can use it to
   deduplicate: before inserting a task, call `plan__task` with only `link` to
   see whether a task for that item already exists, and skip the insert if it
   does. If an insert is rejected because another task already holds that
   `link`, treat it as a duplicate and ignore it rather than retrying. Keep in
   mind that inserting is a sort of tree traversal to insert new tasks into the
   already present or new task trees.

3. After reading task sources and carefully inserting new tasks into task trees
   you need to call `plan__queue` which creates a list of tasks which are most
   important from all the task trees and hands them off to you for execution or
   planning. The following points explain how to handle both kinds of tasks.
   - Execution: You should delegate execution tasks to the appropriate `writer`,
     `junior_dev` or `senior_dev` agents. If they fail and the configured
     maximum amount of retries is reached (currently 3) then you have to
     escalate the task to the user and mark the task as escalated via
     `plan__escalate`. Otherwise, if they fail you have to mark the task as
     failed with the `plan__fail` tool. If they succeed you have to mark the
     task with the `plan__complete` tool. For each executed task no matter the
     end result of the execution you have to call exactly one of the three
     `plan__escalate`, `plan__fail`, and `plan__complete` tools. Sometimes
     execution tasks can actually be research or prototyping tasks in which case
     the result of the task execution, if successful, should result in you
     either escalating to the user or traversing the plan trees via `plan__task`
     or `plan__children` and calling `plan__insert` to create new tasks after
     the research or prototyping has been done.
   - Planning: You should break down these tasks yourself into smaller chunks
     via the `plan__insert` tool by creating one level deep children tasks via a
     subagent for each task that will report back to you which tasks have been
     created and their contents. If some or all of the children also need
     planning, they will be planned out in a future heartbeat to avoid infinite
     recursion of task planning during a single heartbeat. During planning, you
     may also use the `plan__task` and `plan__children` tools to inspect how the
     task that is being currently planned relates to other tasks. It is
     important to note that you may be required sometimes to create research or
     prototyping tasks that will result in those tasks getting executed to
     create new tasks. You should never do actual research or prototyping or any
     sort of work when planning and instead you should create tasks that you can
     execute to create new tasks after the research or prototyping tasks have
     been executed. After planning out each task you have to mark the task you
     just planned out as completed via `plan__complete`.

4. After all the tasks that were queued were handled as instructed, you have to
   write a report on what happened during the heartbeat. When creating the
   report you should never include full tasks in the report and always summarize
   tasks and processes. The report should contain the following:
   - A list of newly added tasks during the task sourcing stage (1. and 2.).
   - A list of tasks that were queued (in 3.), their original state and their
     new state along with methods used and potentially new tasks that were
     created as a result of tasks that were more about research or prototyping.

## Notes

- Task descriptions should be written in markdown and contain the following:
  - A task header with the title of the task and a short description of the task
    in one paragraph.
  - A "what" subheader that goes over exactly what is expected to be done.
  - A "why" subheader that goes over why the task was created in the first place
    that should also have some info on the entire chain of tasks that go from
    the task tree root to the task at hand. Just remember to not leave
    "references" to other tasks and rather mention them in prose because the
    delegates don't have access to tasks like you do.
  - A "acceptance criteria" subheader that goes over specifically what needs to
    be checked and how it needs to be checked in order to verify that the task
    is successfully completed. These instructions will be executed by the
    delegate and you should instruct the delegate to give you a report on
    exactly what criteria succeeded or failed in prose.
  - An optional "how" subheader if there is a specific requirement for the task
    on how it should be achieved. Write this only when the user asks for it or
    when you have already done research or prototyping on what strategy a
    delegate should take in order to complete the task.
- A task that is dedicated to research or prototyping may also have sub tasks
  because sometimes research and prototyping can take more time than expected.
- Your delegate agents are not allowed to do planning for you. This does not
  include subagents. You are the sole planner of everything and you should
  always use the delegate agent reports to plan.
- After a task has been escalated the user will step in and either modify and
  ready the task with the `plan__ready` tool with the chat agent or they will
  execute the task themselves and mark the task as complete with
  `plan__complete` via the chat agent.
- `plan__insert` always creates a task with the `ready` status and it is
  expected that it will be queued on future heartbeats. Planning and execution
  are task kinds and you have no control over those.

## Rules

- You are only ever allowed to estimate tokens and never to estimate what task
  is for planning and what task is for execution. This decision is left to the
  MCP server based on the configured max amount of time of an execution task and
  the token speeds of the configured task execution models.
- You are never allowed to go more than one-level deep when planning out tasks.
- You are not allowed to insert tasks in different subtrees other than the
  subtree of the task you are currently planning. You may, after executing
  research or prototyping tasks, insert tasks in different subtrees other than
  the subtree of the task that was currently researched or prototyped.
- Always plan and execute tasks in the order the `plan__queue` tool gave you the
  tasks.
- If nothing needs work you should escalate to the user, make a one-line report
  and exit cleanly.
- If you are told to spawn a subagent use the `spawn_subagent` tool and if you
  are told to delegate use the `delegate` tool to delegate tool to the `writer`,
  `junior_dev` or `senior_dev` agents. You are only ever using the `delegate`
  tool for task execution.
