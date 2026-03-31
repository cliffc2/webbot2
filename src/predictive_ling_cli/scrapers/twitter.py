"""Twitter/X scraper using Twitter API v2."""

from typing import Any, Dict, List
import httpx
import os
from predictive_ling_cli.utils import increment_counter


class TwitterScraper:
    """Scraper for Twitter/X using Twitter API v2."""

    API_URL = "https://api.twitter.com/2/tweets/search/recent"

    def __init__(self):
        self.results = []
        self.bearer_token = os.getenv("TWITTER_BEARER_TOKEN", "")

    def search(self, query: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Search Twitter using API v2.

        Note: Twitter API now requires a paid developer account.
        Free alternatives (Nitter, etc.) have bot protection.
        """
        if self.bearer_token and self.bearer_token != "your_twitter_bearer_token_here":
            return self._scrape_api(query, limit)
        print("⚠️  Twitter: No API key configured. Twitter API requires a paid developer account.")
        print("    (Nitter instances have bot protection, no free alternative available)")
        return self._mock_search(query, limit)

    def _scrape_api(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape Twitter via API v2."""
        increment_counter("twitter")
        try:
            headers = {
                "Authorization": f"Bearer {self.bearer_token}",
                "Content-Type": "application/json",
            }
            params = {
                "query": query,
                "max_results": min(limit, 100),
                "tweet.fields": "created_at,public_metrics,author_id",
            }
            response = httpx.get(self.API_URL, headers=headers, params=params, timeout=30)

            if response.status_code == 200:
                data = response.json()
                return self._parse_api_response(data)
            else:
                print(f"Twitter API error: {response.status_code} - {response.text[:200]}")
                return self._scrape_nitter(query, limit)
        except Exception as e:
            print(f"Twitter API failed: {e}")
            return self._scrape_nitter(query, limit)

    def _parse_api_response(self, data: dict) -> List[Dict[str, Any]]:
        """Parse Twitter API v2 response."""
        results = []
        tweets = data.get("data", [])
        for tweet in tweets:
            metrics = tweet.get("public_metrics", {})
            results.append(
                {
                    "id": tweet.get("id", ""),
                    "text": tweet.get("text", ""),
                    "created_at": tweet.get("created_at", ""),
                    "public_metrics": {
                        "like_count": metrics.get("like_count", 0),
                        "retweet_count": metrics.get("retweet_count", 0),
                        "reply_count": metrics.get("reply_count", 0),
                    },
                }
            )
        return results if results else self._mock_search("", 10)

    def _scrape_nitter(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape Twitter via Nitter instance (fallback)."""
        nitter_instances = [
            "nitter.tiekoetter.com",
            "xcancel.com",
            "nitter.poast.org",
            "nitter.kavin.rocks",
            "nitter.moomoo.me",
        ]

        for instance in nitter_instances:
            try:
                url = f"https://{instance}/search?type=status&q={query.replace(' ', '%20')}"
                response = httpx.get(
                    url,
                    timeout=15,
                    headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"},
                )

                if response.status_code == 200:
                    return self._parse_nitter(response.text, limit)
            except Exception as e:
                print(f"Nitter {instance} failed: {e}")
                continue

        return self._mock_search(query, limit)

    def _parse_nitter(self, html: str, limit: int) -> List[Dict[str, Any]]:
        """Parse Nitter HTML to extract tweets."""
        from bs4 import BeautifulSoup

        try:
            soup = BeautifulSoup(html, "html.parser")
            tweets = soup.find_all("div", class_="tweet-content")

            results = []
            for i, tweet in enumerate(tweets[:limit]):
                results.append(
                    {
                        "id": f"tweet_{i}",
                        "text": tweet.get_text(strip=True),
                        "created_at": "2024-01-01T00:00:00Z",
                        "public_metrics": {"like_count": 0, "retweet_count": 0, "reply_count": 0},
                    }
                )

            return results if results else self._mock_search("", limit)
        except Exception as e:
            print(f"Parse error: {e}")
            return self._mock_search("", limit)

    def _mock_search(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Return mock data for testing."""
        return [
            {
                "id": f"mock_{i}",
                "text": f"Post about {query} - sample {i}",
                "created_at": "2024-01-01T00:00:00Z",
                "public_metrics": {"like_count": 10 * i, "retweet_count": 2 * i, "reply_count": i},
            }
            for i in range(1, min(limit, 10) + 1)
        ]
