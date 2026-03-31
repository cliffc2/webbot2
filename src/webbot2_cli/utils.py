"""Request counter for tracking API usage."""

from typing import Dict

_request_counts: Dict[str, int] = {
    "twitter": 0,
    "reddit": 0,
    "news": 0,
    "youtube": 0,
    "llm": 0,
}


def increment_counter(service: str) -> None:
    """Increment the counter for a service."""
    if service in _request_counts:
        _request_counts[service] += 1


def get_counts() -> Dict[str, int]:
    """Get all request counts."""
    return _request_counts.copy()


def reset_counts() -> None:
    """Reset all counters to zero."""
    for key in _request_counts:
        _request_counts[key] = 0


def print_summary() -> None:
    """Print request count summary."""
    total = sum(_request_counts.values())
    print("\n" + "=" * 40)
    print("API Request Summary")
    print("=" * 40)
    for service, count in _request_counts.items():
        if count > 0:
            print(f"  {service.capitalize():12} {count:>4} requests")
    print(f"  {'TOTAL':12} {total:>4} requests")
    print("=" * 40)
