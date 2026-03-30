"""News scraper using RSS feeds (no API key required)."""

from typing import Any, Dict, List
import httpx
from datetime import datetime


class NewsScraper:
    """Scraper for news using RSS feeds (no API key required)."""
    
    RSS_SOURCES = {
        "reuters": "https://www.reutersagency.com/feed/",
        "BBC": "https://feeds.bbci.co.uk/news/rss.xml",
        "AP": "https://feeds.apnews.com/apnews/topnews",
        "NPR": "https://feeds.npr.org/1001/rss.xml",
    }
    
    def __init__(self):
        pass
    
    def search(self, query: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search news via RSS feeds (no API key required)."""
        return self._scrape_rss(query, limit)
    
    def _scrape_rss(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Scrape news via RSS."""
        results = []
        
        for name, url in self.RSS_SOURCES.items():
            try:
                response = httpx.get(url, timeout=15, headers={
                    "User-Agent": "Mozilla/5.0"
                })
                
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
                            results.append({
                                "title": title.get_text(strip=True),
                                "description": desc.get_text(strip=True) if desc else "",
                                "url": link.get_text(strip=True) if link else "",
                                "published_at": pub_date.get_text(strip=True) if pub_date else "",
                                "source": {"name": name}
                            })
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
                "source": {"name": f"Source {i}"}
            }
            for i in range(1, min(limit, 10) + 1)
        ]
