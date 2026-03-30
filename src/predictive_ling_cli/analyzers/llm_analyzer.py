"""LLM Analyzer for pattern detection."""

import json
import os
from pathlib import Path
from typing import Any, Dict

import httpx
from dotenv import load_dotenv

load_dotenv()
load_dotenv(os.path.expanduser("~/.predictive-ling.env"))
load_dotenv(os.path.expanduser("~/predictive-ling/.env"))
load_dotenv(".env")


class LLMAnalyzer:
    """Analyzer using LLMs for pattern detection."""

    def __init__(self, model: str = "gpt-4", prompt_type: str = "event_stream"):
        self.model = model
        self.prompt_type = prompt_type
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.system_prompt = self._load_prompt(prompt_type)

    def _load_prompt(self, prompt_type: str) -> str:
        """Load the appropriate prompt template."""
        prompt_dir = Path(__file__).parent.parent / "prompts"

        prompt_map = {
            "event_stream": "event_stream.md",
            "globe_pop": "globe_pop.md",
            "us_pop": "us_pop.md",
        }

        prompt_file = prompt_dir / prompt_map.get(prompt_type, "event_stream.md")

        if prompt_file.exists():
            return prompt_file.read_text()

        return "You are an expert in analyzing linguistic patterns."

    def analyze(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze data using LLM."""
        if not self.api_key:
            return self._mock_analyze(data)

        prompt = self.system_prompt + "\n\n## Data to Analyze\n\n" + json.dumps(data, indent=2)

        openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
        if openrouter_api_key:
            return self._analyze_openrouter(data, openrouter_api_key)

        try:
            base_url = os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1")
            response = httpx.post(
                f"{base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "system", "content": self.system_prompt},
                        {
                            "role": "user",
                            "content": f"Analyze this data:\n\n{json.dumps(data, indent=2)}",
                        },
                    ],
                    "temperature": 0.7,
                },
                timeout=120,
            )
            response.raise_for_status()
            result = response.json()
            content = result["choices"][0]["message"]["content"]

            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return {"raw_analysis": content, "error": "Failed to parse JSON"}

        except Exception as e:
            print(f"LLM API error: {e}, trying mock analysis")
            return self._mock_analyze(data)

    def _analyze_openrouter(self, data: Dict[str, Any], api_key: str) -> Dict[str, Any]:
        """Analyze data using OpenRouter (free tier)."""
        model = os.getenv("OPENROUTER_MODEL", "nvidia/nemotron-3-super-120b-a12b:free")

        try:
            response = httpx.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://predictive-ling-cli",
                    "X-Title": "Predictive Linguistics CLI",
                },
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": self.system_prompt},
                        {
                            "role": "user",
                            "content": f"Analyze this data and return JSON with: metaphors, archetypes, emotional_spikes, contradictions, future_leaks.\n\nData:\n{json.dumps(data, indent=2)}",
                        },
                    ],
                    "temperature": 0.7,
                },
                timeout=180,
            )
            response.raise_for_status()
            result = response.json()
            content = result["choices"][0]["message"]["content"]

            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return {"raw_analysis": content, "error": "Failed to parse JSON"}

        except Exception as e:
            print(f"OpenRouter API error: {e}, using mock analysis")
            return self._mock_analyze(data)

    def _mock_analyze(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Return mock analysis for testing."""
        return {
            "metaphors": [
                {
                    "term": "digital awakening",
                    "context": " AI consciousness discussions",
                    "spread_score": 0.75,
                },
                {
                    "term": "economic reset",
                    "context": " Financial system metaphors",
                    "spread_score": 0.68,
                },
            ],
            "archetypes": [
                {
                    "name": "The Wandering Technologist",
                    "description": "AI expert seeking purpose",
                    "frequency": 45,
                },
                {
                    "name": "The Silent Guardian",
                    "description": "Privacy-focused activist",
                    "frequency": 32,
                },
            ],
            "emotional_spikes": [
                {"topic": "AI regulation", "sentiment": -0.3, "intensity": "high"},
                {"topic": "economic future", "sentiment": -0.5, "intensity": "very_high"},
            ],
            "contradictions": [
                {
                    "narrative": "AI will solve all problems",
                    "counter_narrative": "AI poses existential risk",
                }
            ],
            "future_leaks": [
                {
                    "indicator": "Increased discussion of UBI in mainstream",
                    "confidence": 0.7,
                    "possible_timeline": "6-12 months",
                },
                {
                    "indicator": "Major tech regulation announcement",
                    "confidence": 0.65,
                    "possible_timeline": "3-6 months",
                },
            ],
        }
