"""Markdown report generator - WebBot 2.0 format."""

import json
from datetime import datetime
from typing import Any, Dict, List


class MarkdownReporter:
    """Generate Markdown reports from WebBot 2.0 analysis results."""

    def generate(
        self, data: Dict[str, Any], search_term: str = "", limit: int = 0, timestamp_str: str = ""
    ) -> str:
        """Generate Markdown report."""
        if timestamp_str:
            ts = timestamp_str
        else:
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Handle raw_analysis case - try to extract JSON from LLM response
        if "raw_analysis" in data and "error" in data:
            raw = data.get("raw_analysis", "")
            import re

            json_match = re.search(r"```json\s*(.*?)\s*```", raw, re.DOTALL)
            if json_match:
                try:
                    parsed = json.loads(json_match.group(1))
                    data = parsed
                except:
                    pass

        report_id = data.get("report_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        platform = data.get("platform", "Unknown")

        # Build header
        lines = []
        lines.append("═" * 78)
        lines.append(f"  REPORT: {report_id}_{search_term.lower().replace(' ', '_')}")
        lines.append("═" * 78)
        lines.append("")
        lines.append(f"  search: {search_term}")
        lines.append(f"  limit: {limit}")
        lines.append(f"  timestamp: {report_id}")
        lines.append(f"  platform: {platform}")
        lines.append("")
        lines.append("═" * 78)
        lines.append("  PREDICTIVE LINGUISTICS REPORT - WEBBOT 2.0")
        lines.append("═" * 78)
        lines.append(f"Generated: {ts}")
        lines.append("")

        # Summary section
        summary = data.get("summary", "No summary available.")
        lines.append("─" * 78)
        lines.append("SUMMARY")
        lines.append("─" * 78)
        lines.extend(self._wrap_text(summary, 76))
        lines.append("")

        # Temporal Anomalies
        temporal_anomalies = data.get("temporal_anomalies", [])
        if temporal_anomalies:
            lines.append("─" * 78)
            lines.append("TEMPORAL ANOMALIES (Time-Displacement)")
            lines.append("─" * 78)
            lines.extend(self._format_anomalies_by_confidence(temporal_anomalies))
            lines.append("")

        # Temporal Echoes
        temporal_echoes = data.get("temporal_echoes", [])
        if temporal_echoes:
            lines.append("─" * 78)
            lines.append("TEMPORAL ECHOES")
            lines.append("─" * 78)
            lines.extend(self._format_temporal_echoes(temporal_echoes))
            lines.append("")

        # Memetic Lifecycle
        memetic_lifecycle = data.get("memetic_lifecycle", [])
        if memetic_lifecycle:
            lines.append("─" * 78)
            lines.append("MEMETIC LIFECYCLE ANALYSIS")
            lines.append("─" * 78)
            lines.extend(self._format_memetic_lifecycle(memetic_lifecycle))
            lines.append("")

        # Archetypes
        archetypes = data.get("archetypes", [])
        if archetypes:
            lines.append("─" * 78)
            lines.append("ARCHETYPES (Jungian)")
            lines.append("─" * 78)
            lines.extend(self._format_archetypes(archetypes))
            lines.append("")

        # Entities
        entities = data.get("entities", [])
        if entities:
            lines.append("─" * 78)
            lines.append("ENTITIES DETECTED")
            lines.append("─" * 78)
            lines.extend(self._format_entities(entities))
            lines.append("")

        # Timeframes
        timeframes = data.get("timeframes", [])
        if timeframes:
            lines.append("─" * 78)
            lines.append("PREDICTION TIMEFRAMES")
            lines.append("─" * 78)
            lines.extend(self._format_timeframes(timeframes))
            lines.append("")

        # Detail Words
        detail_words = data.get("detail_words", [])
        if detail_words:
            lines.append("─" * 78)
            lines.append("DETAIL WORDS (Unusual Context)")
            lines.append("─" * 78)
            lines.extend(self._format_detail_words(detail_words))
            lines.append("")

        # Future Leaks
        future_leaks = data.get("future_leaks", [])
        if future_leaks:
            lines.append("─" * 78)
            lines.append("FUTURE LEAK INDICATORS")
            lines.append("─" * 78)
            lines.extend(self._format_future_leaks(future_leaks))
            lines.append("")

        lines.append("═" * 78)
        return "\n".join(lines)

    def _wrap_text(self, text: str, width: int = 76) -> List[str]:
        """Wrap text to specified width."""
        words = text.split()
        lines = []
        current = "  "
        for word in words:
            if len(current) + len(word) + 1 <= width:
                current += word + " "
            else:
                lines.append(current.rstrip())
                current = "  " + word + " "
        lines.append(current.rstrip())
        return lines

    def _format_anomalies_by_confidence(self, anomalies: list) -> List[str]:
        """Format anomalies grouped by confidence level."""
        high_conf = [a for a in anomalies if a.get("confidence", 0) > 0.7]
        med_conf = [a for a in anomalies if 0.5 < a.get("confidence", 0) <= 0.7]
        low_conf = [a for a in anomalies if a.get("confidence", 0) <= 0.5]

        lines = []

        if high_conf:
            lines.append("🔴 HIGH CONFIDENCE (>0.80)")
            for a in high_conf:
                lines.append(
                    f"  │── {a.get('future_reference', 'N/A')} (conf: {a.get('confidence', 0):.2f})"
                )
                lines.append(
                    f"  │    Source: {a.get('platform', 'unknown')} | {a.get('text', '')[:50]}..."
                )
                lines.append("  │")

        if med_conf:
            lines.append("🟡 MEDIUM CONFIDENCE (0.60-0.80)")
            for a in med_conf:
                lines.append(
                    f"  │── {a.get('future_reference', 'N/A')} (conf: {a.get('confidence', 0):.2f})"
                )
                lines.append(
                    f"  │    Source: {a.get('platform', 'unknown')} | {a.get('text', '')[:50]}..."
                )
                lines.append("  │")

        if low_conf:
            lines.append("🟢 LOW CONFIDENCE (<0.60)")
            for a in low_conf:
                lines.append(
                    f"  │── {a.get('future_reference', 'N/A')} (conf: {a.get('confidence', 0):.2f})"
                )
                lines.append(f"  │    Source: {a.get('platform', 'unknown')}")
                lines.append("  │")

        return lines

    def _format_temporal_echoes(self, echoes: list) -> List[str]:
        """Format temporal echoes."""
        lines = []
        for e in echoes:
            change = e.get("intensity_change", "unknown")
            emoji = "📈" if change == "increasing" else "📉" if change == "decreasing" else "➡️"
            lines.append(f"  {emoji} {e.get('meme', 'Unknown')}")
            lines.append(f"      Previous: {e.get('previous_occurrence', 'N/A')}")
            lines.append(f"      Current: {e.get('current_occurrence', 'N/A')}")
            lines.append(f"      Intensity: {change}")
        return lines

    def _format_memetic_lifecycle(self, lifecycle: list) -> List[str]:
        """Format memetic lifecycle stages."""
        stage_names = {
            1: "Awareness",
            2: "Excitement",
            3: "Momentum",
            4: "Critique",
            5: "Integration",
            6: "Nostalgia",
        }

        stage_emojis = {1: "🌱", 2: "🚀", 3: "📈", 4: "🔍", 5: "✅", 6: "📚"}

        lines = []
        for item in lifecycle:
            stage = item.get("stage", 1)
            emoji = stage_emojis.get(stage, "❓")
            name = item.get("pattern", "N/A")
            # Pad name to align
            padded_name = name.ljust(40)
            lines.append(
                f"  {emoji} {padded_name} Stage {stage}: {stage_names.get(stage, 'Unknown')}"
            )
            lines.append(f"     Evidence: {item.get('evidence', 'N/A')[:70]}...")
        return lines

    def _format_archetypes(self, archetypes: list) -> List[str]:
        """Format archetypes."""
        archetype_emojis = {
            "The Catalyst": "⚡",
            "The Herald": "📯",
            "The Shapeshifter": "🎭",
            "The Shadow": "🌑",
            "The Wise Elder": "🦉",
            "The Trickester": "🃏",
            "The Innocent": "🌼",
            "The Warrior": "⚔️",
        }

        lines = []
        for a in archetypes:
            name = a.get("name", "Unknown")
            emoji = archetype_emojis.get(name, "🎭")
            freq = a.get("frequency", 0)
            examples = a.get("examples", [])[:2]
            lines.append(f"  {emoji} {name} (frequency: {freq})")
            for ex in examples:
                if isinstance(ex, list):
                    ex = ", ".join(str(e) for e in ex)
                lines.append(f'      "{str(ex)[:60]}..."')
        return lines

    def _format_entities(self, entities: list) -> List[str]:
        """Format entities."""
        lines = []
        for e in entities:
            weight = e.get("weight", 0)
            emoji = "🔴" if weight > 0.7 else "🟡" if weight > 0.4 else "🟢"
            lines.append(f"  {emoji} {e.get('name', 'Unknown')} (weight: {weight:.2f})")
            themes = ", ".join(e.get("key_themes", [])[:3])
            lines.append(f"      Key themes: {themes}")
        return lines

    def _format_timeframes(self, timeframes: list) -> List[str]:
        """Format prediction timeframes."""
        lines = []
        for t in timeframes:
            tf_type = t.get("type", "Unknown")
            label = t.get("label", "Unknown")
            conf = t.get("confidence", 0)
            emoji = "🔴" if conf > 0.7 else "🟡" if conf > 0.5 else "🟢"
            lines.append(f"  {emoji} {tf_type} ({label}) - conf: {conf:.2f}")
            for ind in t.get("indicators", []):
                lines.append(f"      - {ind}")
        return lines

    def _format_detail_words(self, detail_words: list) -> List[str]:
        """Format detail words."""
        lines = []
        for w in detail_words:
            score = w.get("predictive_score", 0)
            emoji = "🔴" if score > 0.7 else "🟡" if score > 0.4 else "🟢"
            lines.append(f"  {emoji} {w.get('word', 'Unknown')}")
            lines.append(f"      Context: {w.get('unexpected_context', 'N/A')[:60]}...")
            lines.append(
                f"      Timeline: {w.get('emergence_timeline', 'Unknown')} | Score: {score:.2f}"
            )
        return lines

    def _format_future_leaks(self, leaks: list) -> List[str]:
        """Format future leak indicators."""
        lines = []
        for l in leaks:
            conf = l.get("confidence", 0)
            conf_emoji = "🔴" if conf > 0.7 else "🟡" if conf > 0.5 else "🟢"
            timeline = l.get("timeline", l.get("possible_timeline", "unknown"))
            lines.append(f"  {conf_emoji} {l.get('indicator', 'N/A')}")
            lines.append(f"      Confidence: {conf:.2f} | Timeline: {timeline}")
            evidence = l.get("supporting_evidence", [])
            if evidence:
                lines.append(f"      Evidence: {evidence[0][:60]}...")
        return lines
