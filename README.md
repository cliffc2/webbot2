# WebBot 2.0 CLI

![webbot2 preview](webbot2.png)

A Python CLI tool for predictive linguistics analysis using the methodology pioneered by clif high (1993).

**WebBot 2.0** scrapes web content, analyzes for predictive patterns using LLM, and generates reports detecting "future leaks" - time-displaced content ahead of its time.

---

## Quick Start

### 1. Install
```bash
cd webbot2
pip install -e .
```

### 2. Configure API Key
```bash
# Edit .env with your OpenRouter key (free tier)
nano .env
```

### 3. Run Interactive Menu
```bash
./start-webbot2.sh
```

---

## Project Stats

- **Lines of code**: ~5,400
- **Languages**: Bash, Python
- **Structure**:
  - `start-webbot2.sh` — Main interactive menu (~1,770 lines)
  - `src/webbot2_cli/` — Python CLI package (scrapers, analyzers, reporting)
  - `reports/` — Output folder (not tracked, examples may appear)
  - `docs/` — Reference PDFs and documents (not tracked)

---

## Main Menu

```
  [1] Webbot2 Scraper      (Scrapy - any URL → JSON data → LLM analysis)
  [2] Analyze Local File   (Drag & Drop PDF/MD/JSON → Report)
  [3] Run Webbot2          (AutoWebBot - Scrape → Analyze → Report)
  [4] View Results         (Output folder)
  [5] Configuration        (API keys, settings)
  [6] Timeline Tracker     (BETA TEST - batch analyze → timeline view)
  [0] Exit
```

---

## Features

### Web Scraper (Scrapy)
- Single URL scraping with any website
- Quick presets: Hacker News, Reddit, BBC, Wired, Ars Technica
- Extract all links from a page
- View history of previous scrapes

### Analyze Local File (Option 2)
- Drag & drop PDF, Markdown, or JSON files from Finder
- PDFs: auto-extract text → LLM analysis → report
- Markdown: direct LLM analysis → report
- JSON: auto-detect raw data vs pre-analyzed, generate report or re-analyze

### LLM Analysis (OpenRouter)
Free tier models available:
- `qwen/qwen3.6-plus:free` (recommended - balanced)
- `minimax/minimax-m2.5:free` (fast)
- `google/gemma-3-4b-it:free` (fastest, may be rate-limited)

### Report Generation
- **Markdown** - Human-readable reports
- **JSON** - Structured data for further processing
- **Audio/TTS** - Text-to-speech audio reports

---

## Predictive Linguistics Methodology

Based on clif high's original WebBot (1993-2010):

### Entity Categorization
- **GlobalPop** - Humanity's future, local or global
- **USAPop / NationPop** - Geopolitical subsets
- **Markets** - Paper debt, commodities, currency, digital currency
- **Terra** - Planet/physical environment
- **SpaceGoatFarts** - Officially denied, unknown, speculative (UFOs, Area 51)

### Prediction Timeframes
- **IM (Immediacy)**: 3 days to 3 weeks (~21 days)
- **ST (Short Term)**: 4 weeks to 3 months (~90 days)
- **LT (Long Term)**: 3 months to 19 months (~570 days)

### Analysis Output
- Temporal anomalies (time-displacement detection)
- Temporal echoes (recurring patterns with intensity changes)
- Memetic lifecycle stages (Awareness → Excitement → Momentum → Critique → Integration → Nostalgia)
- Archetypes (Catalyst, Herald, Shapeshifter, Shadow, Wise Elder, Trickster, Innocent, Warrior)
- Detail words (unusual context indicators)
- Future leak indicators with confidence scores
- Cross-platform correlation

---

## Commands

### Scrape Web
```bash
webbot2 scrape web "https://example.com" --output data.json
```

### Scrape News
```bash
webbot2 scrape news --query "technology" --limit 50
```

### Scrape Reddit
```bash
webbot2 scrape reddit --subreddit all --query "AI" --limit 25
```

### Analyze
```bash
webbot2 analyze llm data.json --prompt-type webbot
```

### Generate Reports
```bash
webbot2 report markdown analysis.json --output report.md
webbot2 report json analysis.json --output report.json
webbot2 report audio analysis.json --lang en --output report.mp3
```

### Run Full Pipeline
```bash
webbot2 run-all --query "future leaks" --limit 50 --model "qwen/qwen3.6-plus:free"
```

---

## Configuration

Edit `.env` in the project directory:

```bash
# OpenRouter (free tier - recommended)
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_MODEL=qwen/qwen3.6-plus:free

# Or use OpenAI (paid)
OPENAI_API_KEY=sk-...

# Or use local Ollama
# OPENAI_API_BASE=http://localhost:11434/v1
# OPENAI_API_KEY=ollama

# Optional: News APIs
CURRENTS_API_KEY=your_key
NEWSAPI_KEY=your_key
```

Get a free OpenRouter key at: https://openrouter.ai/keys

---

## Output

Results saved to `./reports/`:
- `reports/<timestamp>_<topic>/data.json` - Scraped content
- `reports/<timestamp>_<topic>/analysis.json` - LLM analysis
- `reports/<timestamp>_<topic>/report.md` - Markdown report
- `reports/latest` → symlink to most recent run

---

## Requirements

- Python 3.10+
- Scrapy (for web scraping)
- Dependencies: click, httpx, python-dotenv, beautifulsoup4, gtts, tiktoken, lxml

---

## License

MIT - Based on original WebBot methodology by clif high
