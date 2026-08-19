# DIGEST.md

Shared digest: fetch rules and cron job instructions.

## Cron Job Instructions

When running the digest cron job:

1. Read `DIGEST.md` from your workspace to get feeds, filters and preferences
   and last run date.
2. Get all articles from feeds via `rss__get_articles` with `time_from` as the
   last time this job ran from `DIGEST.md` if it exists.
3. Fetch all the fetched articles with `rss__fetch_article`.
4. Use `memory_store` to remember all the fetched articles that pass filters
   from `DIGEST.md` in your workspace. Use keys like
   `digest:<feed-slug>-<article-slug>` and set values as the article summary in
   1-2 sentences with the link to the article at the end in the following
   format: `# <title>\n\n<summary-paragraph>\n\nLink: <link>\n`.
5. Generate a report summarizing new items grouped by theme, newest first.
6. Write down when the cron job started in the workspace `DIGEST.md`.
7. Deliver the report to the configured channel.
8. If nothing is new, report a single line. If fetch fails, state plainly.

## Rules

- Report Language: English.
- Links: Keep item links in reports.
- On failure: Say so plainly. Never fabricate items.
- Tools: Never use `http_request` or `web_fetch` tools to fetch feeds or
  articles. Always use `rss__get_articles` to fetch feeds and
  `rss__fetch_article` to fetch articles.
