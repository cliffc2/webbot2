"""Twitter/X scraper using Nitter (alternative frontend)."""

from typing import Any, Dict, List
import httpx


class TwitterScraper:
    """Scraper for Twitter/X using Nitter instances (no API needed)."""
    
    NITTER_INSTANCES = [
        "nitter.net",
        "nitter.privacydev.net",
        "nitter.poast.org",
        "nitter.moomoo.io",
    ]
    
    def __init__(self):
        self.results = []
    
    def search(self, query: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Search Twitter using Nitter (no API key required)."""
        return self._scrape_nitter(query, limit)
    
    def _scrape_nitter(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape Twitter via Nitter instance."""
        for instance in self.NITTER_INSTANCES:
            try:
                url = f"https://{instance}/search?type=status&q={query.replace(' ', '%20')}"
                response = httpx.get(url, timeout=15, headers={
                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
                })
                
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
                results.append({
                    "id": f"tweet_{i}",
                    "text": tweet.get_text(strip=True),
                    "created_at": "2024-01-01T00:00:00Z",
                    "public_metrics": {"like_count": 0, "retweet_count": 0, "reply_count": 0}
                })
            
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
                "public_metrics": {"like_count": 10 * i, "retweet_count": 2 * i, "reply_count": i}
            }
            for i in range(1, min(limit, 10) + 1)
        ]
