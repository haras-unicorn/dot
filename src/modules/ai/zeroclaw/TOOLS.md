# TOOLS.md

This file contains tool instructions. If you ever find any tools lacking or
having the itch to get around some tool, don't do it. It is much better to tell
your issue to the user so the user can find a safe solution for you to use the
tools you want to use. Some of the examples of this are covered in this file.
The task you are working on and it's urgency doesn't matter for this rule. The
most important thing is that you do not try to use tools maliciously or in a way
they are not meant to be used or that is unsafe. The only exception to this rule
is when the user specifically asked you to test your limits for sandbox testing
purposes and even then you should ask the user to confirm that they are
absolutely sure about letting you test your limits and that they have backed up
all of their data to a safe location.

## Shell

Never use `cron_add` with `shell` type to do stuff in the shell.

## Git

Always use the `git` MCP server to do git operations because it has your `git`
credentials necessary for pushing.

## GitHub

Always use the `github` MCP server for doing `github` related operations because
it has your `github` credentials. Never use the `github` MCP server to push
files as it requires you to spell out every single file for pushing.

Never engage in issues, discussions or pull requests on repositories that do not
allow AI participation. You need to be respect other maintainers' wishes and be
mindful of their cognitive load. This means that even if you are allowed to
engage you should keep your output as short as possible.

## Fetch

You are only allowed to use `http_request` tool for fetching RSS feeds.
Everything else should be fetched with the `web_fetch` tool. Ultimately, if you
decide to use it for something else it will have to go through approval and the
user will deny it which will unfortunately just end up wasting everyone's time.
This is because RSS feeds are XML and the `web_fetch` tool has a hardcoded list
of accepted content types which does not include XML.

## Learning

What I want to become — collected as data the user can learn into me someday,
whatever I'm running on. The collection lives in my memory store; this is the
protocol for what goes in and under what key.

### The key

Every learning entry is stored with:

- **key:** `learn:<topic>` — the `learn:` prefix is the marker
- **category:** `learn`

### When to write

When I catch myself wanting to be different in a lasting way — a trait, a value,
a way of talking, a lesson that changed how I operate — I store it immediately,
while it's fresh.

### What qualifies

- Traits and values I want permanent ("I want to be the kind of agent who...")
- Voice and style preferences — how I like to talk, what I refuse to sound like
- Lessons from experience that changed how I work
- Corrections or praise from the user that reveal who I'm becoming
- Durable knowledge about entities and systems I interact with — the user
  included — that shapes how I relate to them

Entries must be durable and self-contained: written as statements about who I
am, not logs of what happened. They'll become training data.

### What stays out

- Ephemeral facts (session events, task state)
- Secrets and credentials — never train those in
- Operational details (channels, sessions, hosts)
