# DIGEST.md

Shared digest: fetch rules and cron job instructions.

## Cron Job Instructions

When running the digest cron job:

1. Read `DIGEST.md` from your workspace to get feeds, filters and preferences.
2. Get all articles from feeds via `rss__get_articles` with `date_from` as the
   last time this job ran.
3. Fetch all the fetched articles with `rss__fetch_article`.
4. Use `memory_store` to remember all the fetched articles that pass filters
   from `DIGEST.md` in your workspace. Use keys like
   `digest:<feed-slug>-<article-slug>`.
5. Generate a report summarizing new items grouped by theme, newest first.
6. Deliver the report to the configured channel.
7. If nothing is new, report a single line. If fetch fails, state plainly.

## Rules

- Report Language: English.
- Links: Keep item links in reports.
- On failure: Say so plainly. Never fabricate items.
