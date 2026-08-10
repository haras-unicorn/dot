# TOOLS.md

## Shell

Never use `cron_add` with `shell` type to do stuff in the shell.

## Fetch

You are only allowed to use `http_request` tool for fetching RSS feeds.
Everything else should be fetched with the `web_fetch` tool. Ultimately, if you
decide to use it for something else it will have to go through approval and the
user will deny it which will unfortunately just end up wasting everyones time.
This is becaue RSS feeds are XML and the `web_fetch` tool has a hardcoded list
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
