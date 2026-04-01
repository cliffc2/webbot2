"""Audio/TTS report generator."""

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

try:
    from gtts import gTTS

    GTTS_AVAILABLE = True
except ImportError:
    GTTS_AVAILABLE = False


class AudioReporter:
    """Generate audio reports using TTS."""

    def __init__(self):
        script_dir = Path(__file__).parent.parent.parent
        self.output_dir = script_dir / "reports"
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate(
        self, data: Dict[str, Any], lang: str = "en", output_path: Optional[str] = None
    ) -> str:
        """Generate audio report."""
        if not GTTS_AVAILABLE:
            print("Warning: gTTS not installed. Install with: pip install gtts")
            return self._generate_mock_audio(data, output_path)

        text = self._build_text(data)

        if output_path:
            output_file = Path(output_path)
        else:
            output_file = self.output_dir / f"report_{int(datetime.now().timestamp())}.mp3"

        tts = gTTS(text=text, lang=lang)
        tts.save(str(output_file))

        return str(output_file)

    def _build_text(self, data: Dict[str, Any]) -> str:
        """Build text from analysis data."""
        parts = ["Predictive Linguistics Report. "]

        metaphors = data.get("metaphors", [])
        if metaphors:
            parts.append(f"Emerging metaphors detected: ")
            for m in metaphors[:3]:
                parts.append(f"{m.get('term', '')}. ")

        archetypes = data.get("archetypes", [])
        if archetypes:
            parts.append(f"Archetypes found: ")
            for a in archetypes[:3]:
                parts.append(f"{a.get('name', '')}. ")

        future_leaks = data.get("future_leaks", [])
        if future_leaks:
            parts.append(f"Future leak indicators: ")
            for f in future_leaks[:3]:
                parts.append(f"{f.get('indicator', '')}. ")

        return " ".join(parts)

    def _generate_mock_audio(self, data: Dict[str, Any], output_path: Optional[str]) -> str:
        """Return mock path for when gTTS unavailable."""
        if output_path:
            return output_path
        return str(self.output_dir / "report_mock.mp3")
