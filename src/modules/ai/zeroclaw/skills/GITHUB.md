# GITHUB.md

Poll GitHub notifications to distill them into actionable tasks.

## Instructions

1. Use the `github__list_notifications` tool to get the list of notifications
   you haven't read.

2. Create a list of actionable tasks from those notifications in markdown prose
   as instructed in `HEARTBEAT.md`.

3. Mark the notifications that you just converted into task prose as read. If
   you handled _all_ notifications you should use the
   `github__mark_all_notifications_read` tool for efficiency.

## Notes

- It is important that you ignore non-actionable notifications like PR's or
  issues getting closed.

- You can use tools like `github__get_notification_details` or
  `github__issue_read` to get a better understanding of the problem. You are
  encouraged to use any `github__*` and `plan__*` tools (and others if needed)
  at your disposal to get a better undertsanding of tasks before writing prose
  about them. However, if a task turns out to be complex to understand (you find
  yourself using more than 5 tool calls) you should instead create a task thats
  more about research or prototyping the task itself rather than doing the
  research/prototyping work while planning.

- Spawn a subagent for each notification that will write the task prose.

- Spawn a subagent for marking notifications as read.

- Always include links as full URL's to upstream tasks in task prose when
  possible (i.e. links to issues or PR's).
