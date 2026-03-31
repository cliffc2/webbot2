#!/usr/bin/env python3
"""
Timeline Graph Builder
Creates a relational graph from ALTA predictions for visualization and analysis.
"""

import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime

try:
    import networkx as nx
except ImportError:
    print("Installing networkx...")
    import subprocess

    subprocess.check_call([sys.executable, "-m", "pip", "install", "networkx", "matplotlib"])
    import networkx as nx


def extract_year_from_text(text):
    """Extract 4-digit year from text."""
    match = re.search(r"\b(19|20)\d{2}\b", str(text))
    return int(match.group()) if match else None


def get_doc_year(filename):
    """Extract year from ALTA filename."""
    match = re.search(r"[0-9]{4}", filename)
    return int(match.group()) if match else None


def get_temporal_data(data):
    """Extract temporal data from analysis JSON."""
    raw = data.get("raw_analysis", "")
    if raw:
        try:
            start = raw.find("```json")
            end = raw.find("```", start + 7)
            if start >= 0 and end > start:
                inner = json.loads(raw[start + 7 : end])
                return inner
        except:
            pass
    return {}


def compute_similarity(text1, text2):
    """Simple word-based similarity between two texts."""
    if not text1 or not text2:
        return 0.0

    words1 = set(str(text1).lower().split())
    words2 = set(str(text2).lower().split())

    if not words1 or not words2:
        return 0.0

    intersection = words1 & words2
    union = words1 | words2

    return len(intersection) / len(union) if union else 0.0


def extract_keywords(text, top_n=5):
    """Extract meaningful keywords from text."""
    if not text:
        return []

    # Common stop words to filter
    stop_words = {
        "the",
        "a",
        "an",
        "and",
        "or",
        "but",
        "in",
        "on",
        "at",
        "to",
        "for",
        "of",
        "with",
        "by",
        "from",
        "is",
        "are",
        "was",
        "were",
        "be",
        "been",
        "being",
        "have",
        "has",
        "had",
        "do",
        "does",
        "did",
        "will",
        "would",
        "could",
        "should",
        "may",
        "might",
        "must",
        "shall",
        "can",
        "this",
        "that",
        "these",
        "those",
        "i",
        "you",
        "he",
        "she",
        "it",
        "we",
        "they",
        "their",
        "them",
        "its",
        "as",
        "if",
        "then",
        "so",
        "than",
        "too",
        "very",
        "just",
        "about",
        "into",
        "over",
        "after",
        "before",
        "between",
        "through",
        "during",
        "under",
        "again",
        "further",
        "once",
        "here",
        "all",
        "any",
        "both",
        "each",
        "few",
        "more",
        "most",
        "other",
        "some",
        "such",
        "no",
        "nor",
        "not",
        "only",
        "own",
        "same",
        "down",
        "up",
        "out",
        "off",
        "above",
        "below",
        "because",
        "until",
        "while",
        "how",
        "what",
        "which",
        "who",
        "whom",
        "when",
        "where",
        "why",
    }

    words = str(text).lower().split()
    word_freq = defaultdict(int)

    for word in words:
        word = re.sub(r"[^a-z]", "", word)
        if len(word) > 3 and word not in stop_words:
            word_freq[word] += 1

    # Return top N words
    sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)
    return [w for w, _ in sorted_words[:top_n]]


def build_graph(analyses_dir, similarity_threshold=0.15):
    """Build a NetworkX graph from prediction analyses."""

    G = nx.Graph()

    # Track all nodes and edges
    predictions = []
    themes = defaultdict(list)  # theme -> list of prediction indices

    # First pass: collect all predictions
    for filename in os.listdir(analyses_dir):
        # Accept both analysis.json and *_analysis.json
        if not (filename == "analysis.json" or filename.endswith("_analysis.json")):
            continue

        filepath = os.path.join(analyses_dir, filename)

        try:
            with open(filepath, "r") as f:
                data = json.load(f)
        except:
            continue

        inner = get_temporal_data(data)

        source = inner.get("source", filename.replace("_analysis.json", ""))
        doc_year = get_doc_year(source)

        # Get metadata
        archetypes = inner.get("archetypes", [])
        metaphors = inner.get("metaphors", [])
        future_leaks = inner.get("future_leaks", [])
        temporal_anomalies = inner.get("temporal_anomalies", [])

        # Add source node
        source_node = f"source_{source}"
        G.add_node(source_node, type="source", name=source, year=doc_year, label=source[:20])

        # Process future_leaks
        for i, fl in enumerate(future_leaks):
            indicator = fl.get("indicator", "")
            timeline = fl.get("timeline", "")
            evidence = " ".join(fl.get("supporting_evidence", []))

            pred_year = extract_year_from_text(indicator) or extract_year_from_text(timeline)
            if not pred_year and doc_year:
                # Try to parse timeline (e.g., "3-6 months", "1-2 years")
                nums = re.findall(r"(\d+)", timeline)
                if nums and doc_year:
                    if "month" in timeline.lower():
                        months = (int(nums[0]) + int(nums[-1])) / 2
                        pred_year = int(doc_year + months / 12)
                    elif "year" in timeline.lower():
                        pred_year = doc_year + int(nums[0])

            keywords = extract_keywords(indicator + " " + evidence)

            node_id = f"pred_{len(predictions)}"
            pred_data = {
                "id": node_id,
                "source": source,
                "doc_year": doc_year,
                "pred_year": pred_year,
                "indicator": indicator,
                "timeline": timeline,
                "confidence": fl.get("confidence", 0),
                "keywords": keywords,
                "type": "future_leak",
            }
            predictions.append(pred_data)

            G.add_node(
                node_id,
                type="prediction",
                pred_type="future_leak",
                indicator=indicator[:50],
                year=pred_year or doc_year,
                confidence=fl.get("confidence", 0),
                keywords=",".join(keywords[:3]),
                label=f"{indicator[:15]}... ({pred_year or '?'})",
            )

            # Connect to source
            G.add_edge(source_node, node_id, relationship="from_source")

            # Track keywords for theme grouping
            for kw in keywords[:3]:
                themes[kw].append(node_id)

        # Process temporal_anomalies
        for ta in temporal_anomalies:
            ref = ta.get("future_reference", "")
            text = ta.get("text", "")

            pred_year = extract_year_from_text(ref)
            keywords = extract_keywords(ref + " " + text)

            node_id = f"pred_{len(predictions)}"
            pred_data = {
                "id": node_id,
                "source": source,
                "doc_year": doc_year,
                "pred_year": pred_year,
                "indicator": ref,
                "timeline": "",
                "confidence": ta.get("confidence", 0),
                "keywords": keywords,
                "type": "temporal_anomaly",
            }
            predictions.append(pred_data)

            G.add_node(
                node_id,
                type="prediction",
                pred_type="temporal_anomaly",
                indicator=ref[:50],
                year=pred_year or doc_year,
                confidence=ta.get("confidence", 0),
                keywords=",".join(keywords[:3]),
                label=f"{ref[:15]}... ({pred_year or '?'})",
            )

            G.add_edge(source_node, node_id, relationship="from_source")

            for kw in keywords[:3]:
                themes[kw].append(node_id)

        # Process archetypes
        for arch in archetypes:
            arch_name = arch.get("name", "")
            if arch_name:
                arch_node = f"archetype_{arch_name}"
                G.add_node(
                    arch_node,
                    type="theme",
                    theme_type="archetype",
                    name=arch_name,
                    frequency=arch.get("frequency", 0),
                    label=f"Archetype: {arch_name}",
                )
                G.add_edge(source_node, arch_node, relationship="has_archetype")

        # Process metaphors
        for meta in metaphors:
            term = meta.get("term", "")
            if term:
                meta_node = f"metaphor_{term}"
                G.add_node(
                    meta_node,
                    type="theme",
                    theme_type="metaphor",
                    name=term,
                    spread=meta.get("spread_score", 0),
                    label=f"Metaphor: {term}",
                )
                G.add_edge(source_node, meta_node, relationship="has_metaphor")

    # Second pass: connect related predictions (keyword similarity)
    for i, pred1 in enumerate(predictions):
        for j, pred2 in enumerate(predictions[i + 1 :], i + 1):
            # Check keyword overlap
            kw1 = set(pred1["keywords"][:3])
            kw2 = set(pred2["keywords"][:3])

            if kw1 & kw2:
                sim = len(kw1 & kw2) / len(kw1 | kw2)
                if sim >= similarity_threshold:
                    G.add_edge(
                        pred1["id"],
                        pred2["id"],
                        relationship="keyword_similarity",
                        weight=sim,
                        keywords=list(kw1 & kw2),
                    )

            # Check temporal proximity (within 2 years)
            y1 = pred1.get("pred_year") or pred1.get("doc_year")
            y2 = pred2.get("pred_year") or pred2.get("doc_year")
            if y1 and y2 and abs(y1 - y2) <= 2:
                G.add_edge(
                    pred1["id"],
                    pred2["id"],
                    relationship="temporal_proximity",
                    weight=1.0 - abs(y1 - y2) / 2,
                )

    # Add theme clusters
    for theme, nodes in themes.items():
        if len(nodes) >= 2:
            theme_node = f"theme_{theme}"
            G.add_node(
                theme_node,
                type="theme_cluster",
                name=theme,
                count=len(nodes),
                label=f"Theme: {theme}",
            )

            for node in nodes:
                G.add_edge(theme_node, node, relationship="has_theme")

    return G, predictions


def export_graph(G, output_path, format="json"):
    """Export graph to various formats."""

    if format == "json":
        # Custom JSON export for D3.js or similar
        nodes = []
        edges = []

        for node, attrs in G.nodes(data=True):
            nodes.append(
                {
                    "id": node,
                    "type": attrs.get("type", "unknown"),
                    "label": attrs.get("label", node[:20]),
                    **{k: v for k, v in attrs.items() if k != "label"},
                }
            )

        for u, v, attrs in G.edges(data=True):
            edges.append(
                {
                    "source": u,
                    "target": v,
                    "relationship": attrs.get("relationship", "unknown"),
                    "weight": attrs.get("weight", 1.0),
                }
            )

        with open(output_path, "w") as f:
            json.dump({"nodes": nodes, "edges": edges}, f, indent=2)

        print(f"Exported JSON graph to {output_path}")

    elif format == "graphml":
        nx.write_graphml(G, output_path)
        print(f"Exported GraphML to {output_path}")

    elif format == "gexf":
        try:
            nx.write_gexf(G, output_path)
            print(f"Exported GEXF to {output_path}")
        except:
            print("GEXF export failed (need pygexf), falling back to GraphML")
            nx.write_graphml(G, output_path.replace(".gexf", ".graphml"))

    elif format == "gml":
        nx.write_gml(G, output_path)
        print(f"Exported GML to {output_path}")


def generate_stats(G, predictions):
    """Generate statistics about the graph."""

    print("\n=== Graph Statistics ===")
    print(f"Total nodes: {G.number_of_nodes()}")
    print(f"Total edges: {G.number_of_edges()}")

    # Node counts by type
    type_counts = defaultdict(int)
    for _, attrs in G.nodes(data=True):
        type_counts[attrs.get("type", "unknown")] += 1

    print("\nNode types:")
    for ntype, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        print(f"  {ntype}: {count}")

    # Prediction counts
    sources = [p["source"] for p in predictions]
    print(f"\nTotal predictions: {len(predictions)}")
    print(f"From sources: {len(set(sources))}")

    # Years
    years = [
        p.get("pred_year") or p.get("doc_year")
        for p in predictions
        if p.get("pred_year") or p.get("doc_year")
    ]
    if years:
        print(f"Year range: {min(years)} - {max(years)}")

    # Top keywords
    all_kw = []
    for p in predictions:
        all_kw.extend(p.get("keywords", [])[:3])

    from collections import Counter

    kw_counts = Counter(all_kw).most_common(10)
    if kw_counts:
        print("\nTop keywords:")
        for kw, count in kw_counts:
            print(f"  {kw}: {count}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Build prediction graph from ALTA analyses")
    parser.add_argument("input_dir", help="Directory containing analysis JSON files")
    parser.add_argument("--output", "-o", help="Output file path", default=None)
    parser.add_argument(
        "--format", "-f", choices=["json", "graphml", "gexf", "gml"], default="json"
    )
    parser.add_argument("--threshold", "-t", type=float, default=0.15, help="Similarity threshold")

    args = parser.parse_args()

    if not os.path.isdir(args.input_dir):
        print(f"Error: {args.input_dir} is not a directory")
        sys.exit(1)

    print(f"Building graph from {args.input_dir}...")
    G, predictions = build_graph(args.input_dir, args.threshold)

    generate_stats(G, predictions)

    if args.output:
        export_graph(G, args.output, args.format)
    else:
        # Default output
        base = os.path.basename(args.input_dir.rstrip("/"))
        output = f"{base}_graph.{args.format}"
        export_graph(G, output, args.format)
