"""MyAllies API scraper for market trends and trading data."""

import os
from typing import Dict, List, Any, Optional

import requests


class MyAlliesScraper:
    """Scrape market data from MyAllies Trading API."""

    BASE_URL = "https://api.apps.myallies.com/v1"

    def __init__(self):
        self.api_key = os.getenv("MYALLIES_API_KEY", "")
        if not self.api_key or self.api_key == "your_myallies_api_key":
            raise ValueError("MYALLIES_API_KEY not set in .env")
        self.headers = {"X-Api-Key": self.api_key}

    def get_stock_quote(self, symbol: str) -> Optional[Dict[str, Any]]:
        """Get current stock quote."""
        url = f"{self.BASE_URL}/market/stocks/{symbol}/quote"
        resp = requests.get(url, headers=self.headers, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            return data.get("data", {})
        return None

    def search_companies(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search for companies."""
        url = f"{self.BASE_URL}/companies/search"
        resp = requests.get(
            url, headers=self.headers, params={"q": query, "limit": limit}, timeout=10
        )
        if resp.status_code == 200:
            data = resp.json()
            return data.get("data", [])
        return []

    def get_company_info(self, symbol: str) -> Optional[Dict[str, Any]]:
        """Get company information."""
        url = f"{self.BASE_URL}/companies/{symbol}"
        resp = requests.get(url, headers=self.headers, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            return data.get("data", {})
        return None

    def get_trending(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Get trending stocks (mock - API may not have this endpoint)."""
        symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX", "AMD", "INTC"]
        results = []
        for sym in symbols[:limit]:
            quote = self.get_stock_quote(f"{sym}_SMART")
            if quote:
                results.append({"symbol": sym, "quote": quote})
        return results

    def get_market_news(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Get market news (mock - API may not have this endpoint)."""
        trending = self.get_trending(limit)
        return [{"type": "market", "trending": trending}]

    def run(self, query: str, limit: int = 20) -> Dict[str, Any]:
        """Run analysis on query/topic."""
        results = {
            "source": "MyAllies Trading API",
            "query": query,
            "trending": [],
            "companies": [],
            "status": "success",
        }

        try:
            results["trending"] = self.get_trending(limit)
        except Exception as e:
            results["trending_error"] = str(e)

        try:
            results["companies"] = self.search_companies(query, 10)
        except Exception as e:
            results["search_error"] = str(e)

        return results


def main():
    import json

    scraper = MyAlliesScraper()
    results = scraper.run("tech", limit=10)
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
