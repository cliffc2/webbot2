"""LLM Analyzer for pattern detection - WebBot 2.0 with temporal/memetic analysis."""

import json
import os
from pathlib import Path
from typing import Any, Dict

import httpx
from dotenv import load_dotenv

load_dotenv()
load_dotenv(".env")
load_dotenv(os.path.expanduser("~/.webbot2.env"))
load_dotenv(os.path.expanduser("~/webbot2/.env"))
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

from .temporal_detector import detect_temporal_anomalies
from webbot2_cli.utils import increment_counter


class LLMAnalyzer:
    """Analyzer using LLMs for pattern detection - WebBot 2.0 methodology."""

    def __init__(self, model: str = "gpt-4", prompt_type: str = "webbot"):
        self.model = model
        self.prompt_type = prompt_type
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.system_prompt = self._load_prompt(prompt_type)
        self.temporal_detector_enabled = True

    def _load_prompt(self, prompt_type: str) -> str:
        """Load the appropriate prompt template."""
        prompt_dir = Path(__file__).parent.parent / "prompts"

        prompt_map = {
            "webbot": "webbot_analysis.md",
            "event_stream": "event_stream.md",
            "globe_pop": "globe_pop.md",
            "us_pop": "us_pop.md",
        }

        prompt_file = prompt_dir / prompt_map.get(prompt_type, "webbot_analysis.md")

        if prompt_file.exists():
            return prompt_file.read_text()

        return "You are an expert in analyzing linguistic patterns using WebBot methodology."

    def analyze(self, data: Any) -> Dict[str, Any]:
        """Analyze data using LLM with WebBot methodology."""
        # Wrap list in dict if needed
        if isinstance(data, list):
            data = {"items": data}

        temporal_anomalies = []
        if self.temporal_detector_enabled:
            temporal_anomalies = detect_temporal_anomalies(data)
            data["_temporal_anomalies_detected"] = temporal_anomalies

        # Check for API keys - OpenRouter first (free tier), then OpenAI
        openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
        if openrouter_api_key:
            increment_counter("llm")
            return self._analyze_openrouter(data, openrouter_api_key)

        if not self.api_key:
            print("WARNING: No API key configured.")
            print("  → Set OPENROUTER_API_KEY in .env for free tier")
            print("  → Or set OPENAI_API_KEY for direct OpenAI access")
            raise RuntimeError(
                "No API key configured. Add OPENROUTER_API_KEY or OPENAI_API_KEY to your .env file"
            )

        try:
            increment_counter("llm")
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
            print(f"ERROR: LLM API call failed: {e}")
            raise

    def _analyze_openrouter(self, data: Dict[str, Any], api_key: str) -> Dict[str, Any]:
        """Analyze data using OpenRouter (free tier) with WebBot methodology."""
        model = os.getenv("OPENROUTER_MODEL", "qwen/qwen3.6-plus-preview:free")

        try:
            increment_counter("llm")
            response = httpx.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://webbot2-cli",
                    "X-Title": "WebBot 2.0 CLI",
                },
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": self.system_prompt},
                        {
                            "role": "user",
                            "content": f"Analyze this data using WebBot 2.0 methodology. Return ONLY valid JSON with: temporal_anomalies, memetic_lifecycle, archetypes, metaphors, contradictions, future_leaks, cross_platform_patterns, summary.\n\nData:\n{json.dumps(data, indent=2)}",
                        },
                    ],
                    "temperature": 0.7,
                    "max_tokens": 4000,
                },
                timeout=180,
            )
            response.raise_for_status()
            result = response.json()
            message = result["choices"][0]["message"]
            content = message.get("content")

            # Handle reasoning models that may return content in reasoning field
            if not content:
                reasoning = message.get("reasoning", "")
                if reasoning:
                    content = reasoning
                else:
                    raise ValueError(
                        f"No content in response. Full response: {json.dumps(result)[:500]}"
                    )

            try:
                analysis = json.loads(content)
                return analysis
            except json.JSONDecodeError:
                return {"raw_analysis": content, "error": "Failed to parse JSON"}

        except httpx.HTTPStatusError as e:
            print(f"ERROR: OpenRouter API returned HTTP {e.response.status_code}")
            if e.response.status_code == 401:
                print("  → Invalid API key. Get a free key at https://openrouter.ai/keys")
                print("  → Set OPENROUTER_API_KEY in your .env file")
            elif e.response.status_code == 429:
                print("  → Rate limit exceeded. Try again later or use a different model")
            elif e.response.status_code == 403:
                print("  → Access denied. Check if the model requires paid credits")
            raise
        except httpx.ConnectError as e:
            print(f"ERROR: Cannot connect to OpenRouter API: {e}")
            raise
        except Exception as e:
            print(f"ERROR: OpenRouter API call failed: {e}")
            raise

    def _mock_analyze_webbot(
        self, data: Dict[str, Any], temporal_anomalies: list
    ) -> Dict[str, Any]:
        """Return mock analysis with WebBot methodology for testing."""
        return {
            "temporal_anomalies": temporal_anomalies[:5]
            if temporal_anomalies
            else [
                {
                    "text": "By 2030, the old systems will have collapsed completely...",
                    "future_reference": "2030",
                    "confidence": 0.72,
                    "platform": "twitter",
                    "match_type": "future_year",
                }
            ],
            "memetic_lifecycle": [
                {
                    "pattern": "AI consciousness awakening",
                    "stage": 2,
                    "stage_name": "Excitement",
                    "evidence": "Rapid viral spread, memes about AI 'waking up', exponential engagement",
                },
                {
                    "pattern": "Economic reset narrative",
                    "stage": 3,
                    "stage_name": "Momentum",
                    "evidence": "Mainstream media coverage, podcast discussions, increasing normalization",
                },
            ],
            "archetypes": [
                {
                    "name": "The Herald",
                    "frequency": 28,
                    "examples": [
                        "Posts claiming 'something big is coming'",
                        "References to 'the shift'",
                    ],
                },
                {
                    "name": "The Catalyst",
                    "frequency": 19,
                    "examples": ["AI as the trigger for change", "Technology as disruptor"],
                },
                {
                    "name": "The Shadow",
                    "frequency": 15,
                    "examples": [
                        "Suppressed truths about tech elites",
                        "Hidden agenda discussions",
                    ],
                },
            ],
            "metaphors": [
                {
                    "term": "digital awakening",
                    "context": "AI consciousness discussions",
                    "spread_score": 0.78,
                    "is_emerging": True,
                },
                {
                    "term": "economic reset",
                    "context": "Financial system metaphors",
                    "spread_score": 0.65,
                    "is_emerging": False,
                },
                {
                    "term": "the great unraveling",
                    "context": "Social collapse narrative",
                    "spread_score": 0.58,
                    "is_emerging": True,
                },
            ],
            "contradictions": [
                {
                    "narrative": "AI will solve all problems",
                    "counter_narrative": "AI poses existential risk",
                    "tension_level": "high",
                },
                {
                    "narrative": "Decentralization is the future",
                    "counter_narrative": "Centralized control increasing",
                    "tension_level": "medium",
                },
            ],
            "future_leaks": [
                {
                    "indicator": "Increased discussion of UBI in mainstream",
                    "confidence": 0.75,
                    "timeline": "6-12 months",
                    "supporting_evidence": [
                        "Multiple platform spikes",
                        "Mainstream media mentions increasing",
                    ],
                },
                {
                    "indicator": "Major tech regulation announcement",
                    "confidence": 0.68,
                    "timeline": "3-6 months",
                    "supporting_evidence": [
                        "Political discourse ramping up",
                        "EU/US policy discussions",
                    ],
                },
            ],
            "cross_platform_patterns": [
                {
                    "pattern": "AI rights movement",
                    "platforms": ["twitter", "reddit", "youtube"],
                    "synchronization": "synchronized",
                },
                {
                    "pattern": "digital identity crisis",
                    "platforms": ["reddit", "twitter"],
                    "synchronization": "emerging",
                },
            ],
            "summary": "Analysis detected high excitement stage memetic patterns around AI consciousness. Temporal anomalies indicate strong future-displacement language. The Herald archetype is prominent, signaling perceived upcoming changes. Cross-platform synchronization suggests these patterns are converging across all monitored sources.",
        }

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
