# AI Prompt Globe POP (Population-Level Pattern Detection)

## Context
You are analyzing population-level linguistic patterns across global social media to detect 
large-scale cultural shifts, emerging trends, and archetypal resonances.

## Task
Analyze the provided data for global-scale patterns:

1. **Cross-Cultural Metaphors**: Metaphors appearing across multiple cultures/languages
2. **Global Archetypes**: Archetypal patterns with worldwide resonance
3. **Sentiment Waves**: Large-scale emotional movements
4. **Emerging Narratives**: New storytelling patterns gaining global traction

## Output Format
Return a JSON object:
{
  "cross_cultural_metaphars": [{"term": "string", "cultures": [string], "spread_score": float}],
  "global_archetypes": [{"name": "string", "global_reach": string, "resonance_score": float}],
  "sentiment_waves": [{"emotion": "string", "regions": [string], "magnitude": float}],
  "emerging_narratives": [{"theme": "string", "description": "string", "adoption_rate": string}]
}

## Guidelines
- Look for patterns spanning multiple regions
- Consider语言的跨文化传播
- Identify universal human concerns emerging in discourse
