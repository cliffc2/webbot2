"""News scraper using Currents API or NewsAPI or RSS feeds."""

from typing import Any, Dict, List
import httpx
import os
from datetime import datetime
from predictive_ling_cli.utils import increment_counter


class NewsScraper:
    """Scraper for news using Currents API (with fallbacks)."""

    RSS_SOURCES = {
        "reuters": "https://www.reutersagency.com/feed/",
        "BBC": "https://feeds.bbci.co.uk/news/rss.xml",
        "AP": "https://feeds.apnews.com/apnews/topnews",
        "NPR": "https://feeds.npr.org/1001/rss.xml",
    }

    def __init__(self):
        self.currents_key = os.getenv("CURRENTS_API_KEY", "")
        self.newsapi_key = os.getenv("NEWS_API_KEY", "")

    def search(self, query: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search news via Currents API, NewsAPI, or RSS."""
        if self.currents_key and self.currents_key != "your_currents_api_key_here":
            return self._scrape_currents(query, limit)
        if self.newsapi_key and self.newsapi_key != "your_news_api_key_here":
            return self._scrape_newsapi(query, limit)
        print("ℹ️  News: No API keys found. Using free RSS feeds (BBC, Reuters).")
        print("    For more sources, add NEWS_API_KEY or CURRENTS_API_KEY to .env")
        return self._scrape_rss(query, limit)

    def _scrape_currents(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape news via Currents API (free tier: 600/day)."""
        increment_counter("news")
        try:
            response = httpx.get(
                "https://api.currentsapi.services/v1/search",
                params={
                    "keywords": query,
                    "language": "en",
                    "page_size": min(limit, 50),
                    "apiKey": self.currents_key,
                },
                timeout=30,
            )

            if response.status_code == 200:
                data = response.json()
                results = []
                for article in data.get("news", [])[:limit]:
                    url = article.get("url", "")
                    source_name = "Unknown"
                    if url:
                        from urllib.parse import urlparse

                        source_name = urlparse(url).netloc.replace("www.", "")
                    results.append(
                        {
                            "title": article.get("title", ""),
                            "description": article.get("description", ""),
                            "url": url,
                            "published_at": article.get("published", ""),
                            "source": {"name": source_name},
                        }
                    )
                return results if results else self._scrape_rss(query, limit)
            else:
                print(f"Currents API error: {response.status_code}")
                if self.newsapi_key:
                    return self._scrape_newsapi(query, limit)
                return self._scrape_rss(query, limit)
        except Exception as e:
            print(f"Currents API failed: {e}")
            if self.newsapi_key:
                return self._scrape_newsapi(query, limit)
            return self._scrape_rss(query, limit)

    def _scrape_newsapi(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape news via NewsAPI."""
        increment_counter("news")
        try:
            response = httpx.get(
                "https://newsapi.org/v2/everything",
                params={
                    "q": query,
                    "apiKey": self.newsapi_key,
                    "pageSize": min(limit, 100),
                    "sortBy": "publishedAt",
                },
                timeout=30,
            )

            if response.status_code == 200:
                data = response.json()
                results = []
                for article in data.get("articles", [])[:limit]:
                    results.append(
                        {
                            "title": article.get("title", ""),
                            "description": article.get("description", ""),
                            "url": article.get("url", ""),
                            "published_at": article.get("publishedAt", ""),
                            "source": article.get("source", {}),
                        }
                    )
                return results if results else self._scrape_rss(query, limit)
            else:
                print(f"NewsAPI error: {response.status_code}")
                return self._scrape_rss(query, limit)
        except Exception as e:
            print(f"NewsAPI failed: {e}")
            return self._scrape_rss(query, limit)

    def _scrape_rss(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape news via RSS feeds."""
        results = []

        for name, url in self.RSS_SOURCES.items():
            try:
                response = httpx.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})

                if response.status_code == 200:
                    from bs4 import BeautifulSoup

                    soup = BeautifulSoup(response.text, "xml")

                    items = soup.find_all("item")[:10]
                    for item in items:
                        title = item.find("title")
                        desc = item.find("description")
                        link = item.find("link")
                        pub_date = item.find("pubDate")

                        if title:
                            results.append(
                                {
                                    "title": title.get_text(strip=True),
                                    "description": desc.get_text(strip=True) if desc else "",
                                    "url": link.get_text(strip=True) if link else "",
                                    "published_at": pub_date.get_text(strip=True)
                                    if pub_date
                                    else "",
                                    "source": {"name": name},
                                }
                            )
            except Exception as e:
                print(f"RSS {name} failed: {e}")
                continue

        return results if results else self._mock_search(query, limit)

    def _mock_search(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Return mock data for testing."""
        return [
            {
                "title": f"News article about {query} - {i}",
                "description": f"Description for article {i}",
                "url": f"https://example.com/article_{i}",
                "published_at": "2024-01-01T00:00:00Z",
                "source": {"name": f"Source {i}"},
            }
            for i in range(1, min(limit, 10) + 1)
        ]
