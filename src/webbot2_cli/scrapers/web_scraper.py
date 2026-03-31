"""Scrapy-based web scraper for any website."""

import os
import subprocess
import json
from typing import Dict, List, Any, Optional


class WebScraper:
    """Scrape websites using Scrapy CLI."""

    def __init__(self):
        pass

    def fetch_url(self, url: str) -> Optional[str]:
        """Fetch a URL using scrapy."""
        try:
            result = subprocess.run(
                ["scrapy", "fetch", "--nolog", url], capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0 and result.stdout:
                return result.stdout
            return None
        except Exception:
            return None

    def run(self, query: str, limit: int = 5) -> Dict[str, Any]:
        """Scrape websites based on query URL or term."""
        results = {"source": "Scrapy Web Scraper", "query": query, "pages": [], "status": "success"}

        # If query looks like a URL, fetch it directly
        if query.startswith("http://") or query.startswith("https://"):
            content = self.fetch_url(query)
            if content:
                results["pages"].append(
                    {
                        "url": query,
                        "content_length": len(content),
                        "content": content[:10000],  # Limit content size
                    }
                )
            else:
                results["status"] = "failed"
                results["error"] = "Failed to fetch URL"
        else:
            # Try to fetch the URL with query as search term
            urls_to_try = [
                f"https://news.ycombinator.com/",
                f"https://reddit.com/r/worldnews/",
            ]

            for url in urls_to_try[:limit]:
                content = self.fetch_url(url)
                if content:
                    results["pages"].append(
                        {"url": url, "content_length": len(content), "preview": content[:1000]}
                    )

        return results


def main():
    import sys

    scraper = WebScraper()
    query = sys.argv[1] if len(sys.argv) > 1 else "https://news.ycombinator.com/"
    results = scraper.run(query)
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
