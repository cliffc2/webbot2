"""CLI entry point for Predictive Linguistics CLI."""

import json
import os
from pathlib import Path
from typing import Optional

import click
from dotenv import load_dotenv

load_dotenv()
load_dotenv(os.path.expanduser("~/.predictive-ling.env"))
load_dotenv(os.path.expanduser("~/predictive-ling/.env"))
load_dotenv(".env")

from predictive_ling_cli.scrapers.twitter import TwitterScraper
from predictive_ling_cli.scrapers.reddit import RedditScraper
from predictive_ling_cli.scrapers.youtube import YouTubeScraper
from predictive_ling_cli.scrapers.news import NewsScraper
from predictive_ling_cli.analyzers.llm_analyzer import LLMAnalyzer
from predictive_ling_cli.reporting.markdown import MarkdownReporter
from predictive_ling_cli.reporting.json_output import JSONReporter
from predictive_ling_cli.reporting.audio import AudioReporter


def get_output_dir() -> Path:
    """Get or create the output directory."""
    output_dir = Path.home() / ".predictive-ling" / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


@click.group()
@click.version_option(version="0.1.0")
def main():
    """Predictive Linguistics CLI - Multi-agent meme/archetype detection and synthesis."""
    pass


@main.group()
def scrape():
    """Scrape data from various platforms."""
    pass


@scrape.command("twitter")
@click.option("--query", "-q", default="future leaks", help="Search query")
@click.option("--limit", "-l", default=100, help="Number of tweets to fetch")
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def scrape_twitter(query: str, limit: int, output: Optional[str]):
    """Scrape data from Twitter/X."""
    click.echo(f"Scraping Twitter with query: {query}")
    scraper = TwitterScraper()
    results = scraper.search(query, limit=limit)

    if output:
        Path(output).write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output}")
    else:
        output_path = get_output_dir() / f"twitter_{query.replace(' ', '_')}.json"
        output_path.write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output_path}")

    return results


@scrape.command("reddit")
@click.option("--subreddit", "-s", default="all", help="Subreddit to search")
@click.option("--query", "-q", default="", help="Search query")
@click.option("--limit", "-l", default=100, help="Number of posts to fetch")
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def scrape_reddit(subreddit: str, query: str, limit: int, output: Optional[str]):
    """Scrape data from Reddit."""
    click.echo(f"Scraping Reddit r/{subreddit} with query: {query}")
    scraper = RedditScraper()
    results = scraper.search(subreddit, query, limit=limit)

    if output:
        Path(output).write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output}")
    else:
        output_path = get_output_dir() / f"reddit_{subreddit}_{query.replace(' ', '_')}.json"
        output_path.write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output_path}")

    return results


@scrape.command("youtube")
@click.option("--query", "-q", default="future leaks", help="Search query")
@click.option("--limit", "-l", default=50, help="Number of videos to fetch")
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def scrape_youtube(query: str, limit: int, output: Optional[str]):
    """Scrape data from YouTube."""
    click.echo(f"Scraping YouTube with query: {query}")
    scraper = YouTubeScraper()
    results = scraper.search(query, limit=limit)

    if output:
        Path(output).write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output}")
    else:
        output_path = get_output_dir() / f"youtube_{query.replace(' ', '_')}.json"
        output_path.write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output_path}")

    return results


@scrape.command("news")
@click.option("--query", "-q", default="future leaks", help="Search query")
@click.option("--limit", "-l", default=50, help="Number of articles to fetch")
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def scrape_news(query: str, limit: int, output: Optional[str]):
    """Scrape data from news sources."""
    click.echo(f"Scraping news with query: {query}")
    scraper = NewsScraper()
    results = scraper.search(query, limit=limit)

    if output:
        Path(output).write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output}")
    else:
        output_path = get_output_dir() / f"news_{query.replace(' ', '_')}.json"
        output_path.write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output_path}")

    return results


@main.group()
def analyze():
    """Analyze scraped data for patterns."""
    pass


@analyze.command("llm")
@click.argument("input_file", type=click.Path(exists=True))
@click.option("--model", "-m", default="gpt-4", help="LLM model to use")
@click.option(
    "--prompt-type",
    "-p",
    default="event_stream",
    type=click.Choice(["event_stream", "globe_pop", "us_pop"]),
)
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def analyze_llm(input_file: str, model: str, prompt_type: str, output: Optional[str]):
    """Analyze data using LLM."""
    click.echo(f"Analyzing {input_file} with prompt: {prompt_type}")
    data = json.loads(Path(input_file).read_text())
    analyzer = LLMAnalyzer(model=model, prompt_type=prompt_type)
    results = analyzer.analyze(data)

    if output:
        Path(output).write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output}")
    else:
        output_path = get_output_dir() / f"analysis_{prompt_type}.json"
        output_path.write_text(json.dumps(results, indent=2))
        click.echo(f"Results written to {output_path}")

    return results


@main.group()
def report():
    """Generate reports from analysis results."""
    pass


@report.command("markdown")
@click.argument("input_file", type=click.Path(exists=True))
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def report_markdown(input_file: str, output: Optional[str]):
    """Generate Markdown report."""
    click.echo(f"Generating Markdown report from {input_file}")

    data = json.loads(Path(input_file).read_text())
    reporter = MarkdownReporter()
    report_content = reporter.generate(data)

    if output:
        Path(output).write_text(report_content)
        click.echo(f"Report written to {output}")
    else:
        output_path = get_output_dir() / "report.md"
        output_path.write_text(report_content)
        click.echo(f"Report written to {output_path}")

    return report_content


@report.command("json")
@click.argument("input_file", type=click.Path(exists=True))
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def report_json(input_file: str, output: Optional[str]):
    """Generate JSON report."""
    click.echo(f"Generating JSON report from {input_file}")
    data = json.loads(Path(input_file).read_text())
    reporter = JSONReporter()
    report_content = reporter.generate(data)

    if output:
        Path(output).write_text(json.dumps(report_content, indent=2))
        click.echo(f"Report written to {output}")
    else:
        output_path = get_output_dir() / "report.json"
        output_path.write_text(json.dumps(report_content, indent=2))
        click.echo(f"Report written to {output_path}")

    return report_content


@report.command("audio")
@click.argument("input_file", type=click.Path(exists=True))
@click.option("--lang", "-l", default="en", help="Language code")
@click.option("--output", "-o", type=click.Path(), help="Output file path")
def report_audio(input_file: str, lang: str, output: Optional[str]):
    """Generate audio report (TTS)."""
    click.echo(f"Generating audio report from {input_file}")
    data = json.loads(Path(input_file).read_text())
    reporter = AudioReporter()
    audio_path = reporter.generate(data, lang=lang, output_path=output)

    click.echo(f"Audio report written to {audio_path}")
    return audio_path


@main.command("run-all")
@click.option("--query", "-q", default="future leaks", help="Search query for all platforms")
@click.option("--limit", "-l", default=50, help="Number of items per platform")
@click.option("--model", "-m", default="gpt-4", help="LLM model to use")
def run_all(query: str, limit: int, model: str):
    """Run the complete pipeline: scrape -> analyze -> report."""
    click.echo("=" * 50)
    click.echo("Starting Predictive Linguistics Pipeline")
    click.echo("=" * 50)

    output_dir = get_output_dir()

    click.echo("\n[1/4] Scraping Twitter...")
    twitter_scraper = TwitterScraper()
    twitter_data = twitter_scraper.search(query, limit=limit)
    twitter_file = output_dir / "tmp_twitter.json"
    twitter_file.write_text(json.dumps(twitter_data, indent=2))
    click.echo(f"  -> Fetched {len(twitter_data)} tweets")

    click.echo("\n[2/4] Scraping Reddit...")
    reddit_scraper = RedditScraper()
    reddit_data = reddit_scraper.search("all", query, limit=limit)
    reddit_file = output_dir / "tmp_reddit.json"
    reddit_file.write_text(json.dumps(reddit_data, indent=2))
    click.echo(f"  -> Fetched {len(reddit_data)} posts")

    click.echo("\n[3/4] Scraping YouTube...")
    youtube_scraper = YouTubeScraper()
    youtube_data = youtube_scraper.search(query, limit=limit)
    youtube_file = output_dir / "tmp_youtube.json"
    youtube_file.write_text(json.dumps(youtube_data, indent=2))
    click.echo(f"  -> Fetched {len(youtube_data)} videos")

    click.echo("\n[4/4] Scraping News...")
    news_scraper = NewsScraper()
    news_data = news_scraper.search(query, limit=limit)
    news_file = output_dir / "tmp_news.json"
    news_file.write_text(json.dumps(news_data, indent=2))
    click.echo(f"  -> Fetched {len(news_data)} articles")

    click.echo("\n[5/6] Running LLM Analysis...")
    combined_data = {
        "twitter": twitter_data,
        "reddit": reddit_data,
        "youtube": youtube_data,
        "news": news_data,
    }
    analyzer = LLMAnalyzer(model=model, prompt_type="event_stream")
    analysis_results = analyzer.analyze(combined_data)
    analysis_file = output_dir / "analysis.json"
    analysis_file.write_text(json.dumps(analysis_results, indent=2))
    click.echo("  -> Analysis complete")

    click.echo("\n[6/6] Generating Reports...")

    md_reporter = MarkdownReporter()
    md_content = md_reporter.generate(analysis_results)
    (output_dir / "report.md").write_text(md_content)
    click.echo("  -> Markdown report generated")

    json_reporter = JSONReporter()
    json_content = json_reporter.generate(analysis_results)
    (output_dir / "report.json").write_text(json.dumps(json_content, indent=2))
    click.echo("  -> JSON report generated")

    audio_reporter = AudioReporter()
    audio_path = audio_reporter.generate(analysis_results)
    click.echo("  -> Audio report generated")

    click.echo("\n" + "=" * 50)
    click.echo("Pipeline Complete!")
    click.echo(f"Output directory: {output_dir}")
    click.echo("=" * 50)

    return analysis_results


if __name__ == "__main__":
    main()
