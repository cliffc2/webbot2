# WebBot 2.0 CLI

![webbot2 preview](webbot2.png)

A Python CLI tool for predictive linguistics analysis using the methodology pioneered by clif high (1993).

**WebBot 2.0** scrapes news APIs and web content, analyzes for predictive patterns using LLM, and generates reports detecting "future leaks" - time-displaced content ahead of its time.

---

## Quick Start

### 1. Install
```bash
pip install -e .
```

### 2. Run Interactive Menu
```bash
./start-webbot2.sh
```

### 3. Quick Analysis
```bash
webbot2 scrape news --query "AI future" --limit 25
```

---

## Main Menu

```
  [1] Web Scraper        (Scrapy - any URL)
  [2] Analyze Local File (PDF/MD → report)
  [3] Quick Analysis     (Currents API → analyze → report)
  [4] NewsAPI Analysis  (NewsAPI → analyze → report)
  [5] Run Pipeline       (choose platforms)
  [6] View Results       (output folder)
  [7] Configuration     (API key, settings)
  [8] Timeline Tracker  (batch analyze → timeline view)
  [0] Exit
```

---

## Features

### Web Scraper (Scrapy)
- Single URL scraping with any website
- Quick presets: Hacker News, Reddit, BBC, Wired, Ars Technica
- Extract all links from a page
- View history and analyze with LLM

### News Sources
- **Currents API** - 600 requests/day (recommended)
- **NewsAPI** - 100 requests/day
- RSS feeds fallback (BBC, Reuters, AP, NPR)

### LLM Analysis (OpenRouter)
Free tier models available:
- `qwen/qwen3.6-plus-preview:free` (recommended)
- `nvidia/nemotron-3-super-120b-a12b:free`
- `minimax/minimax-m2.5:free`

---

## Predictive Linguistics Methodology

Based on clif high's original WebBot (1993-2010):

### Entity Categorization
- **GlobalPop** - Humanity's future, local or global
- **Markets** - Paper debt, commodities, currency, digital currency
- **Terra** - Planet/physical environment
- **SpaceGoatFarts** - Officially denied, unknown, speculative (UFOs, Area 51)

### Prediction Timeframes
- **IM (Immediacy)**: 3 days to 3 weeks
- **ST (Short Term)**: 4 weeks to 3 months
- **LT (Long Term)**: 3 months to 19 months

### Analysis Output
- Temporal anomalies (time-displacement detection)
- Memetic lifecycle stages (Awareness → Excitement → Momentum → Critique → Integration → Nostalgia)
- Archetypes (Catalyst, Herald, Shapeshifter, Shadow, Wise Elder, Trickster, Innocent, Warrior)
- Detail words (words in unexpected contexts - high predictive value)
- Future leak indicators with confidence scores
- Cross-platform pattern correlation

---

## Commands

### Scrape News
```bash
webbot2 scrape news --query "technology" --limit 50
```

### Analyze
```bash
webbot2 analyze llm data.json --prompt-type webbot
```

### Generate Report
```bash
webbot2 report markdown analysis.json --output report.md
```

### Full Pipeline
```bash
webbot2 run-all --query "AI trends" --limit 25
```

---

## Configuration

Create `~/.webbot2.env`:
```bash
# OpenRouter (free)
OPENROUTER_API_KEY=sk-or-...
OPENROUTER_MODEL=qwen/qwen3.6-plus-preview:free

# News API (optional)
CURRENTS_API_KEY=your_key
NEWSAPI_KEY=your_key
```

---

## Output

Results saved to `~/.webbot2/output/`:
- `analysis.json` - Structured analysis
- `report.md` - Markdown report
- `report.json` - JSON report

---

## Requirements

- Python 3.10+
- Dependencies: click, httpx, python-dotenv, beautifulsoup4, scrapy

---

## License

MIT - Based on original WebBot methodology by clif high