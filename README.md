# AI News Briefing

> **Built on [Horizon](https://github.com/Thysrael/Horizon)**, an open-source LLM news aggregator by Thysrael (MIT). Horizon provides the pipeline engine. This repo is my adaptation of it: an AI-only scoring profile, curated sources and quotas, two bug fixes to Horizon's code, and Windows automation. It does not contain Horizon itself; `scripts/setup.ps1` clones it at the tested commit.

A daily AI news briefing: the last 24 hours of AI news from 16 sources, scored by Claude against a custom rubric, de-duplicated, written up, and emailed every morning at 6:30.

**[Read the case study →](https://simonoconnordev.github.io/ai-news-briefing/)** · [How it works in detail](https://simonoconnordev.github.io/ai-news-briefing/how-it-works.html)

## What's Horizon's and what's mine

| From Horizon (open source) | Added in this repo |
|---|---|
| Pipeline engine and source collectors | Tool selection: five approaches compared against written requirements |
| LLM scoring framework and profile system | `profiles/ai-news`: AI-only relevance rule and rubric |
| Duplicate merging, quota selection | 16 curated AI sources and category quotas, including combined Reddit RSS feeds |
| Write-ups with web and history search | Two fixes to Horizon's code (`patches/`) |
| Markdown archive, email delivery | Tuning of thresholds, model and concurrency; scheduling, logging and setup scripts |

## How it works

```
Task Scheduler (06:30)                      ← added here
  └─ run-horizon.ps1                        ← added here
       └─ Horizon pipeline (open source), configured by config/ and profiles/ai-news
            1 Fetch     16 feeds: AI labs, tech press, newsletters, Reddit (RSS), Hacker News, trending GitHub repos
            2 Merge     same URL from several sources → one item
            3 Score     Claude rates each item 0–10 against profiles/ai-news (JSON: score, reason, summary, tags)
            4 Filter    keep AI news ≥ 6, deep-dive blogs ≥ 5
            5 De-dupe   Claude groups articles about the same story, keeps the best
            6 Balance   per-category quotas, max 20 items
            7 Enrich    Claude writes background / impact / discussion, using web search and past briefings
            8 Deliver   Markdown archive + HTML email via Gmail SMTP
```

A typical weekday run collects ~100 items and emails ~10, in about 6½ minutes and 160–200k LLM tokens.

## What's in this repo

| Path | What it is |
|---|---|
| [`config/config.json`](config/config.json) | Sources, model, score thresholds, category quotas, email settings |
| [`profiles/ai-news/`](profiles/ai-news/) | Custom scoring and write-up profile: AI-only relevance rule and rubric |
| [`patches/horizon-fixes.patch`](patches/horizon-fixes.patch) | Two fixes to Horizon (see below) |
| [`scripts/setup.ps1`](scripts/setup.ps1) | Clones Horizon at the tested commit, applies the patch, installs, copies config |
| [`scripts/run-horizon.ps1`](scripts/run-horizon.ps1) | What the scheduled task runs; writes a log per run |
| [`scripts/register-task.ps1`](scripts/register-task.ps1) | Creates the daily Windows scheduled task |
| [`docs/`](docs/) | The case study and the detailed explainer (served by GitHub Pages) |

## Fixes to Horizon

Tested against Horizon commit [`d7406f7`](https://github.com/Thysrael/Horizon/commit/d7406f738c711df82b8f060fa1d5e9999d36cca0) (3 Nov 2026). Both fixes have been submitted upstream with tests: [Thysrael/Horizon#220](https://github.com/Thysrael/Horizon/pull/220) and [Thysrael/Horizon#221](https://github.com/Thysrael/Horizon/pull/221). The upstream version of the retry also honours `Retry-After`.

1. **LLM calls all failing with 400.** Anthropic's API now rejects `temperature` with *"Extra inputs are not permitted"*. Horizon retries without it, but didn't recognise that wording. The fix adds one line to the error matcher in `src/ai/client.py`.
2. **Reddit RSS rate limiting.** Reddit answers rapid RSS requests with 429. `src/scrapers/rss.py` now retries up to three times with 15/30/45-second backoff. The config also reads Reddit through two combined multi-subreddit feeds instead of Horizon's scraper, which Reddit blocks.

## Setup (Windows)

Requires Git and Python 3.11+.

```powershell
git clone https://github.com/simonoconnordev/ai-news-briefing.git
cd ai-news-briefing
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

Then:

1. Add your Anthropic API key and a Gmail App Password to `Horizon\.env`.
2. Set `email.email_address` in `Horizon\data\config.json` and your address in `Horizon\data\subscribers.json`.
3. Test with a short window: `Horizon\.venv\Scripts\horizon.exe --hours 4` (run from inside `Horizon\`).
4. Schedule it: `powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1 -At 6:30am`

## Notes

- Built with [Claude Code](https://claude.com/claude-code). I set the goals, chose the approach and reviewed every test run. Claude Code did the research, configuration and code fixes.
- Released under the MIT License. Horizon is © Thysrael, also MIT. See [LICENSE](LICENSE).
