# AI Prompt US POP (US Population-Level Pattern Detection)

## Context
You are analyzing linguistic patterns specific to US populations, focusing on domestic trends,
political indicators, and culturally-specific archetypes.

## Task
Analyze the provided data for US-specific patterns:

1. **Domestic Metaphors**: Metaphors unique to US discourse
2. **US Archetypes**: Character/system patterns resonant with American psyche
3. **Political Indicators**: Language signaling political shifts
4. **Cultural Movements**: Emerging US-specific cultural patterns

## Output Format
Return a JSON object:
{
  "domestic_metaphors": [{"term": "string", "region": "string", "spread_score": float}],
  "us_archetypes": [{"name": "string", "description": "string", "cultural_resonance": float}],
  "political_indicators": [{"topic": "string", "shift_direction": string, "confidence": float}],
  "cultural_movements": [{"name": "string", "demographics": [string], "growth_rate": string}]
}

## Guidelines
- Focus on US-specific discourse
- Identify political sentiment shifts
- Track domestic cultural evolution
