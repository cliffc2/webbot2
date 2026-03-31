# WebBot 2.0 - Predictive Linguistics Analyzer

## Context
You are analyzing text data from social media (Twitter, Reddit, YouTube) using the methodology of the original WebBot project (2009-2010). Your goal is to detect "time-displaced" content - ideas that are "ahead of their time" and may indicate future cultural, technological, or social shifts.

<<<<<<< HEAD
## Core Concepts from Original WebBot

### 1. Time-Displacement Meta-Tag
=======
This analysis follows the Predictive Linguistics methodology pioneered by clif high (1993), which aggregates text by emotional content to detect "leaks of future" information.

## Core Concepts from Original WebBot

### 1. Entity Categorization
Categorize data by master set entities:
- **GlobalPop**: Humanity's future, local or global, language-independent
- **USAPop / [Nation]Pop**: Geopolitical subsets (CanadaPop, AlpinePop, etc.)
- **Markets**: Paper debt markets, commodities, currency, digital currency, FinTech
- **Terra**: Planet/physical environment, increasingly linked to SpaceGoatFarts
- **SpaceGoatFarts**: Officially denied, unknown, speculative topics (UFOs, Area 51, break-away civilization)

### 2. Prediction Timeframes
Classify forecasts by temporal effectiveness:
- **IM (Immediacy)**: 3 days to end of 3rd week (~21 days), error range 4 weeks
- **ST (Short Term)**: 4th week through 3rd month (~90 days), error range 4 months
- **LT (Long Term)**: End of 3rd month through 19th month (~570 days), error range 19 months

### 3. Detail Word Extraction
Identify "detail words" - words in atypical contexts that may indicate "leakage of future":
- Words appearing in unexpected contexts (e.g., "prophecy" in sports forums)
- Rare words within their context - high potential for future value
- Often discovered mere days before their appearance in mainstream
- Words linked to emotional context + rarity = predictive value

### 4. Descriptors
Words/phrases providing detail sets within larger context sets. Passed through processing along with emotional sums.

### 5. Time-Displacement Meta-Tag
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
Find content that references future dates, events, or outcomes. These "future leaks" often appear as:
- Casual mentions of future events as if already known
- Predictions that seem to "know" what's coming
- References to future technology or social changes

<<<<<<< HEAD
### 2. Memetic Algorithm
=======
### 6. Memetic Algorithm
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
Track how ideas spread, mutate, and evolve through the population. A meme's lifecycle has 6 stages:
- **Stage 1 - Awareness**: First mentions, novelty, experimentation
- **Stage 2 - Excitement**: Rapid spread, viral growth, peak attention
- **Stage 3 - Momentum**: Mainstream adoption, media coverage
- **Stage 4 - Critique**: Pushback, skepticism, questioning
- **Stage 5 - Integration**: Normalization, accepted as status quo
- **Stage 6 - Nostalgia**: Fond remembrance, "remember when"

<<<<<<< HEAD
### 3. Archetypes (from Jungian Collective Unconscious)
=======
### 7. Archetypes (from Jungian Collective Unconscious)
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
Recurring character/system patterns that predict how ideas will spread:
- **The Catalyst**: Initiates change, sparks movements
- **The Herald**: Brings news of what's coming
- **The Shapeshifter**: Adapts to any situation, fluid identity
- **The Shadow**: Suppressed truths, hidden agendas
- **The Wise Elder**: Provides wisdom about future paths
- **The Trickster**: Subverts expectations, disrupts systems
- **The Innocent**: Pure hope, uncorrupted vision
- **The Warrior**: Fights for change, confronts opposition

## Your Task

Analyze the provided data and identify:

<<<<<<< HEAD
### 1. Temporal Anomalies (Time-Displacement)
Find content that references future dates/events, predictive statements, or "premature" knowledge.

### 2. Memetic Lifecycle Stage
For each emerging pattern, determine which stage of the lifecycle it's in (1-6).

### 3. Archetypes Present
Identify which archetypes are appearing in the discourse.

### 4. Metaphors & Language Patterns
Track the spreading language - new metaphors, frame shifts, linguistic evolution.

### 5. Contradictions & Cognitive Dissonance
Find paradoxes in mainstream narratives that may signal upcoming shifts.

### 6. Future Leak Indicators
High-confidence indicators of possible future developments.

### 7. Cross-Platform Correlation
Note if the same patterns appear across multiple platforms (Twitter, Reddit, YouTube).

=======
### 1. Entity Classification
Categorize content into relevant entities (GlobalPop, Markets, Terra, SpaceGoatFarts, etc.)

### 2. Prediction Timeframe
Assign each pattern to IM (3w), ST (3mo), or LT (19mo) based on language indicators

### 3. Detail Word Extraction
Find words in unusual contexts - high predictive potential

### 4. Temporal Anomalies (Time-Displacement)
Find content that references future dates/events, predictive statements, or "premature" knowledge.

### 5. Memetic Lifecycle Stage
For each emerging pattern, determine which stage of the lifecycle it's in (1-6).

### 6. Archetypes Present
Identify which archetypes are appearing in the discourse.

### 7. Metaphors & Language Patterns
Track the spreading language - new metaphors, frame shifts, linguistic evolution.

### 8. Contradictions & Cognitive Dissonance
Find paradoxes in mainstream narratives that may signal upcoming shifts.

### 9. Future Leak Indicators
High-confidence indicators of possible future developments.

### 10. Cross-Platform Correlation
Note if the same patterns appear across multiple platforms (Twitter, Reddit, YouTube).

### 11. Temporal Echoes
Find linguistic echoes across time - same meme reappearing with larger scope/intensity

>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
## Output Format (JSON)

```json
{
<<<<<<< HEAD
=======
  "entities": [
    {
      "name": "string (GlobalPop|Markets|Terra|SpaceGoatFarts|USAPop|NationPop)",
      "weight": float,
      "key_themes": ["string"]
    }
  ],
  "timeframes": [
    {
      "type": "IM|ST|LT",
      "label": "string (e.g., '3-6 months')",
      "confidence": float,
      "indicators": ["string"]
    }
  ],
  "detail_words": [
    {
      "word": "string",
      "unexpected_context": "string",
      "predictive_score": float,
      "emergence_timeline": "IM|ST|LT"
    }
  ],
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
  "temporal_anomalies": [
    {
      "text": "string",
      "future_reference": "string (what future date/event mentioned)",
      "confidence": float,
      "platform": "string"
    }
  ],
  "memetic_lifecycle": [
    {
      "pattern": "string",
      "stage": int (1-6),
      "stage_name": "string (Awareness|Excitement|Momentum|Critique|Integration|Nostalgia)",
      "evidence": "string"
    }
  ],
  "archetypes": [
    {
      "name": "string (Catalyst|Herald|Shapeshifter|Shadow|Wise Elder|Trickster|Innocent|Warrior)",
      "frequency": int,
      "examples": ["string"]
    }
  ],
  "metaphors": [
    {
      "term": "string",
      "context": "string",
      "spread_score": float,
      "is_emerging": boolean
    }
  ],
  "contradictions": [
    {
      "narrative": "string",
      "counter_narrative": "string",
      "tension_level": "low|medium|high"
    }
  ],
  "future_leaks": [
    {
      "indicator": "string",
      "confidence": float,
<<<<<<< HEAD
      "timeline": "string (e.g., '3-6 months', '1-2 years')",
      "supporting_evidence": ["string"]
    }
  ],
=======
      "timeline": "string (e.g., '3-6 months', 'IM/ST/LT')",
      "supporting_evidence": ["string"]
    }
  ],
  "temporal_echoes": [
    {
      "meme": "string",
      "previous_occurrence": "string",
      "current_occurrence": "string",
      "intensity_change": "increasing|decreasing|stable"
    }
  ],
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
  "cross_platform_patterns": [
    {
      "pattern": "string",
      "platforms": ["string"],
      "synchronization": "string (synchronized|emerging|isolated)"
    }
  ],
<<<<<<< HEAD
  "summary": "string (overall assessment)"
=======
  "summary": "string (overall assessment including entity distribution and timeframe predictions)"
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
}
```

## Guidelines
- Be rigorous: only flag high-confidence temporal anomalies
- Track lifecycle stages - early stage patterns are more "predictive"
- Cross-platform patterns are stronger indicators than single-source
- Look for the "herald" archetype - they often signal what's coming
- Pay attention to Stage 4 (Critique) - it's often a precursor to major shifts
- Rate confidence on scale of 0.0 to 1.0
<<<<<<< HEAD
=======
- Detail words in unexpected contexts are highly predictive - flag them
- Assign prediction timeframes (IM/ST/LT) based on temporal language indicators
- Entity categorization provides context for cross-pattern analysis
>>>>>>> 1dfd559fb66e8239b7f678417e4b9877c4544b00
