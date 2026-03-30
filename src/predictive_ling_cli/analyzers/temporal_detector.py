"""Temporal Anomaly Detector - finds future date/event references."""

import re
from datetime import datetime, timedelta
from typing import Any, Dict, List
from dataclasses import dataclass


@dataclass
class TemporalAnomaly:
    text: str
    future_reference: str
    confidence: float
    platform: str
    match_type: str


class TemporalDetector:
    """Detects time-displaced content (future references) in text."""

    def __init__(self):
        self.current_year = datetime.now().year
        self.future_patterns = self._compile_patterns()

    def _compile_patterns(self) -> List[Dict[str, Any]]:
        """Compile regex patterns for future date detection."""
        return [
            {
                "name": "future_year",
                "pattern": r"\b(20[2-9][0-9]|21[0-9]{2})\b",
                "type": "future_year",
            },
            {
                "name": "future_date",
                "pattern": r"\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+([1-9]|[12][0-9]|3[01]),?\s+(20[2-9][0-9]|21[0-9]{2})\b",
                "type": "explicit_date",
            },
            {
                "name": "relative_future",
                "pattern": r"\b(in\s+(the\s+)?(next|coming)\s+(few|\d+)\s+(years?|months?|decades?))\b",
                "type": "relative",
            },
            {
                "name": "future_tense_prediction",
                "pattern": r"\b(will\s+happen|is\s+going\s+to\s+happen|is\s+about\s+to|coming\s+soon|inevitable|when\s+.*\s+arrives?)\b",
                "type": "prediction",
            },
            {
                "name": "future_event_mention",
                "pattern": r"\b(the\s+)?(election|war|collapse|revolution|awakening|reset|event|shift|cataclysm)\s+(of|is|will|in)\s+[0-9]{4}\b",
                "type": "future_event",
            },
            {
                "name": "countdown",
                "pattern": r"\b(only\s+)?\d+\s+(days?|weeks?|months?|years?)\s+(until|left|away|before)\b",
                "type": "countdown",
            },
        ]

    def detect(self, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Detect temporal anomalies in scraped data."""
        anomalies = []

        for platform, items in data.items():
            if not isinstance(items, list):
                continue

            for item in items:
                text = ""
                if isinstance(item, dict):
                    text = item.get("text", "") or item.get("content", "") or item.get("title", "")
                elif isinstance(item, str):
                    text = item

                if not text:
                    continue

                found = self._scan_text(text, platform)
                anomalies.extend(found)

        return anomalies

    def _scan_text(self, text: str, platform: str) -> List[Dict[str, Any]]:
        """Scan a single text for temporal anomalies."""
        results = []
        text_lower = text.lower()

        for pattern_def in self.future_patterns:
            matches = re.finditer(pattern_def["pattern"], text, re.IGNORECASE)

            for match in matches:
                reference = match.group(0)
                confidence = self._calculate_confidence(pattern_def["type"], reference, text_lower)

                results.append(
                    {
                        "text": text[:200] + "..." if len(text) > 200 else text,
                        "future_reference": reference,
                        "confidence": confidence,
                        "platform": platform,
                        "match_type": pattern_def["type"],
                    }
                )

        return results

    def _calculate_confidence(self, match_type: str, reference: str, text: str) -> float:
        """Calculate confidence score based on match type."""
        base_confidence = {
            "future_year": 0.5,
            "explicit_date": 0.7,
            "relative": 0.6,
            "prediction": 0.4,
            "future_event": 0.75,
            "countdown": 0.65,
        }.get(match_type, 0.5)

        certainty_words = ["definitely", "certainly", "know", "will", "inevitable", "guaranteed"]
        if any(word in text for word in certainty_words):
            base_confidence = min(1.0, base_confidence + 0.15)

        speculation_words = ["maybe", "perhaps", "might", "could", "possibly", "probably"]
        if any(word in text for word in speculation_words):
            base_confidence = max(0.1, base_confidence - 0.2)

        return round(base_confidence, 2)

    def filter_high_confidence(
        self, anomalies: List[Dict[str, Any]], threshold: float = 0.5
    ) -> List[Dict[str, Any]]:
        """Filter to only high-confidence anomalies."""
        return [a for a in anomalies if a["confidence"] >= threshold]


def detect_temporal_anomalies(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Convenience function for temporal detection."""
    detector = TemporalDetector()
    return detector.detect(data)
