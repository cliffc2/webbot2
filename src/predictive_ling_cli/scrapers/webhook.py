"""Webhook.site scraper for testing and monitoring."""

import os
import requests
from typing import Dict, List, Any, Optional


class WebhookScraper:
    """Test webhook endpoint using webhook.site (or custom endpoint)."""

    def __init__(self):
        self.webhook_url = os.getenv("WEBHOOK_URL", "")
        if not self.webhook_url:
            raise ValueError("WEBHOOK_URL not set in .env")

    def send_payload(self, data: Dict[str, Any]) -> bool:
        """Send payload to webhook URL."""
        try:
            resp = requests.post(self.webhook_url, json=data, timeout=10)
            return resp.status_code in [200, 201, 202]
        except Exception:
            return False

    def run(self, query: str, limit: int = 10) -> Dict[str, Any]:
        """Test webhook with sample data."""
        results = {
            "source": "Webhook.site",
            "query": query,
            "webhook_url": self.webhook_url,
            "test_results": [],
            "status": "success",
        }

        test_data = {
            "query": query,
            "timestamp": str(int(__import__("time").time())),
            "test_number": 1,
        }

        success = self.send_payload(test_data)
        results["test_results"].append({"sent": True, "success": success, "data": test_data})

        return results


def main():
    import json

    scraper = WebhookScraper()
    results = scraper.run("test", limit=1)
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
