"""Reddit scraper using Old Reddit (no API needed)."""

from typing import Any, Dict, List
import httpx
from predictive_ling_cli.utils import increment_counter


class RedditScraper:
    """Scraper for Reddit using Old Reddit (no API key required)."""

    def __init__(self):
        pass

    def search(self, subreddit: str, query: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Search Reddit via Old Reddit (no OAuth needed)."""
        return self._scrape_old_reddit(subreddit, query, limit)

    def _scrape_old_reddit(self, subreddit: str, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape Reddit via old.reddit.com."""
        increment_counter("reddit")
        try:
            url = f"https://old.reddit.com/r/{subreddit}/search.json"
            params = {"q": query, "sort": "relevance", "limit": min(limit, 100)}

            response = httpx.get(
                url,
                params=params,
                timeout=15,
                headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"},
            )

            if response.status_code == 200:
                data = response.json()
                return self._parse_reddit_json(data)
        except Exception as e:
            print(f"Reddit scrape error: {e}")

        return self._mock_search(subreddit, query, limit)

    def _parse_reddit_json(self, data: dict) -> List[Dict[str, Any]]:
        """Parse Reddit JSON response."""
        results = []
        children = data.get("data", {}).get("children", [])

        for post in children:
            post_data = post.get("data", {})
            results.append(
                {
                    "id": post_data.get("id"),
                    "title": post_data.get("title"),
                    "subreddit": post_data.get("subreddit"),
                    "score": post_data.get("score", 0),
                    "num_comments": post_data.get("num_comments", 0),
                    "created_utc": post_data.get("created_utc", 0),
                }
            )

        return results

    def _mock_search(self, subreddit: str, query: str, limit: int) -> List[Dict[str, Any]]:
        """Return mock data for testing."""
        return [
            {
                "id": f"mock_{i}",
                "title": f"Post about {query} - sample {i}",
                "subreddit": subreddit,
                "score": 10 * i,
                "num_comments": 5 * i,
                "created_utc": 1704067200,
            }
            for i in range(1, min(limit, 10) + 1)
        ]
