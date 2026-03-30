# Predictive Linguistics CLI

![webbot2 preview](webbot2.png)

A Python CLI tool for multi-agent predictive linguistics workflow: cross-platform meme/archetype detection and synthesis, inspired by Clif High's research and spirittechie's work on https://github.com/spirittechie/predictive-linguistics-webbot

**No API keys required!** Uses free alternative frontends for scraping and free LLM tiers for analysis.

---

## Quick Start

### 1. Install
```bash
cd predictive-ling-cli
pip install -e .
```

### 2. Interactive Menu (Recommended)
```bash
./start-webbot2.sh
```
The menu-driven interface lets you:
- Run full pipeline or individual steps
- Select platforms, models, report formats
- Configure API keys and test connections
- View output files

### 3. CLI Usage (Alternative)
```bash
predictive-ling run-all --query "AI future" --limit 25
```

### 4. View Results
```bash
cat ~/.predictive-ling/output/report.md
```

### 5. Configure (Optional)
For free LLM analysis, get a free key at https://openrouter.ai/keys:
```bash
echo 'OPENROUTER_API_KEY=your_key_here' > ~/.predictive-ling.env
```

---

## How It Works (No API Keys Needed!)

| Platform | Method | No API Key |
|----------|--------|------------|
| Twitter/X | Nitter (nitter.net) | ✓ |
| Reddit | Old Reddit (old.reddit.com) | ✓ |
| YouTube | Invidious (yewtu.be) | ✓ |
| News | RSS feeds (BBC, Reuters, AP, NPR) | ✓ |
| LLM | OpenRouter free tier | Optional |

---

## Commands

### Full Pipeline
```bash
predictive-ling run-all --query "future leaks" --limit 50
```

### Scrape Individual Platforms
```bash
# Twitter via Nitter
predictive-ling scrape twitter --query "AI" --limit 100

# Reddit via Old Reddit
predictive-ling scrape reddit --subreddit technology --query "AI"

# YouTube via Invidious
predictive-ling scrape youtube --query "future" --limit 50

# News via RSS
predictive-ling scrape news --query "trends" --limit 50
```

### Generate Reports
```bash
# Markdown
predictive-ling report markdown analysis.json --output report.md

# JSON
predictive-ling report json analysis.json --output report.json

# Audio (TTS)
predictive-ling report audio analysis.json --output report.mp3
```

### Analyze with LLM
```bash
predictive-ling analyze llm data.json --model nvidia/nemotron-3-super-120b-a12b:free
```

---

## Configuration

### Environment Variables

Create `~/.predictive-ling.env`:
```bash
# OpenRouter (free - recommended)
OPENROUTER_API_KEY=sk-or-...
OPENROUTER_MODEL=nvidia/nemotron-3-super-120b-a12b:free

# OR local Ollama
# OPENAI_API_BASE=http://localhost:11434/v1
# OPENAI_API_KEY=ollama
```

### Available Free LLM Models

| Model | Description |
|-------|-------------|
| `nvidia/nemotron-3-super-120b-a12b:free` | Largest (120B), slowest |
| `minimax/minimax-m2.5:free` | Good balance |
| `openrouter/free` | Auto-selects best available |

---

## Output

Results saved to `~/.predictive-ling/output/`:
- `report.md` - Markdown report
- `report.json` - Structured JSON
- `report_*.mp3` - Audio TTS summary

---

## opencode Integration

Custom commands available in opencode TUI:

```
/analyze <query>   # Run analysis pipeline
/pl-status         # Check output status
```

---

## Interactive Menu

Launch the interactive menu:
```bash
./start-webbot2.sh
```

### Menu Options

| Option | Description |
|--------|-------------|
| 1 | Run Full Pipeline (scrape + analyze + report) |
| 2 | Scrape Data (Twitter, Reddit, YouTube, News, All) |
| 3 | Analyze Data (select model & prompt type) |
| 4 | Generate Reports (Markdown, JSON, Audio) |
| 5 | View Output Files |
| 6 | Configuration (API keys, models, test) |
| 7 | Help/Info |

### Menu Features
- Query input
- Limit/quantity input
- Platform selection
- Report format selection
- Analysis model picker
- Free LLM model list
- API key configuration & testing

---

## Commands Reference

| Command | Description |
|---------|-------------|
| `predictive-ling scrape twitter` | Scrape Twitter/X |
| `predictive-ling scrape reddit` | Scrape Reddit |
| `predictive-ling scrape youtube` | Scrape YouTube |
| `predictive-ling scrape news` | Scrape news RSS |
| `predictive-ling analyze llm` | Analyze with LLM |
| `predictive-ling report markdown` | Generate Markdown |
| `predictive-ling report json` | Generate JSON |
| `predictive-ling report audio` | Generate TTS audio |
| `predictive-ling run-all` | Full pipeline |

---

## Requirements

- Python 3.10+
- Dependencies: click, httpx, python-dotenv, beautifulsoup4, gtts

---

## License

MIT