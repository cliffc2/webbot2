"""YouTube scraper using Invidious (alternative frontend)."""

from typing import Any, Dict, List
import httpx
from predictive_ling_cli.utils import increment_counter


class YouTubeScraper:
    """Scraper for YouTube using Invidious instances (no API key required)."""

    INVIDIOUS_INSTANCES = [
        "invidious.snopyta.org",
        "invidious.kavin.rocks",
        "invidious.jingl.xyz",
        "yewtu.be",
    ]

    def __init__(self):
        pass

    def search(self, query: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search YouTube via Invidious (no API key required).

        Note: Free Invidious instances may be blocked. Consider adding
        a YouTube API key to .env for reliable access.
        """
        results = self._scrape_invidious(query, limit)
        if not results or all("mock" in r.get("id", "") for r in results):
            print(
                "⚠️  YouTube: Free scrapers blocked. Add YOUTUBE_API_KEY to .env for reliable access."
            )
        return results

    def _scrape_invidious(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape YouTube via Invidious."""
        increment_counter("youtube")
        for instance in self.INVIDIOUS_INSTANCES:
            try:
                url = f"https://{instance}/api/v1/search"
                params = {"q": query, "type": "video", "limit": limit}

                response = httpx.get(url, params=params, timeout=15)

                if response.status_code == 200:
                    data = response.json()
                    return self._parse_invidious(data)
            except Exception as e:
                print(f"Invidious {instance} failed: {e}")
                continue

        return self._mock_search(query, limit)

    def _parse_invidious(self, data: list) -> List[Dict[str, Any]]:
        """Parse Invidious API response."""
        results = []

        for item in data:
            if item.get("type") == "video":
                results.append(
                    {
                        "id": item.get("videoId"),
                        "title": item.get("title"),
                        "description": item.get("description"),
                        "channel_id": item.get("authorId"),
                        "published_at": item.get("published"),
                    }
                )

        return results

    def _mock_search(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Return mock data for testing."""
        return [
            {
                "id": f"mock_{i}",
                "title": f"Video about {query} - sample {i}",
                "description": f"Description for video {i}",
                "channel_id": f"channel_{i}",
                "published_at": "2024-01-01T00:00:00Z",
            }
            for i in range(1, min(limit, 10) + 1)
        ]
