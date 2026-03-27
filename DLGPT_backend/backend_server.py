from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

app = FastAPI()

class XSummaryRequest(BaseModel):
    userId: str
    maxItems: int
    summaryType: str
    timeWindowHours: Optional[int] = None


def iso_z(dt: datetime) -> str:
    return dt.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def get_fake_feed_items(now: datetime) -> list[dict]:
    return [
        {
            "id": "1",
            "authorName": "Example Author",
            "authorHandle": "exampleauthor",
            "text": "A major new AI product release is driving discussion across the feed.",
            "publishedAt": now - timedelta(minutes=40),
            "themeName": "AI product launches",
            "reason": "Representative of the strongest theme in the analysed batch.",
            "entryType": "post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "2",
            "authorName": "Market Watcher",
            "authorHandle": "marketwatcher",
            "text": "Several posts are reacting to rate expectations and market sentiment.",
            "publishedAt": now - timedelta(minutes=65),
            "themeName": "Markets and macro",
            "reason": "High concentration of similar market commentary in the feed.",
            "entryType": "repost",
            "isReply": False,
            "isAd": False,
            "isRepost": True,
            "isQuotePost": False,
        },
        {
            "id": "3",
            "authorName": "Builder Notes",
            "authorHandle": "buildernotes",
            "text": "Founders are discussing distribution, product iteration, and fast launches.",
            "publishedAt": now - timedelta(hours=3),
            "themeName": "Startup and builder commentary",
            "reason": "Strong representation of builder-focused discussion in the snapshot.",
            "entryType": "quote_post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": True,
        },
        {
            "id": "4",
            "authorName": "AI Daily",
            "authorHandle": "aidaily",
            "text": "Benchmarks and model comparisons are spreading quickly across the timeline.",
            "publishedAt": now - timedelta(hours=5),
            "themeName": "AI product launches",
            "reason": "Reinforces the concentration of AI product discussion.",
            "entryType": "post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "5",
            "authorName": "Macro Lens",
            "authorHandle": "macrolens",
            "text": "Traders are debating the rate path and the next macro catalysts.",
            "publishedAt": now - timedelta(hours=9),
            "themeName": "Markets and macro",
            "reason": "Adds another clear market-focused signal from the feed.",
            "entryType": "post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "6",
            "authorName": "Ship Fast",
            "authorHandle": "shipfast",
            "text": "Operators are trading notes on shipping cadence and early user feedback loops.",
            "publishedAt": now - timedelta(hours=14),
            "themeName": "Startup and builder commentary",
            "reason": "Supports the builder and startup cluster in the analysed batch.",
            "entryType": "post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "7",
            "authorName": "Quant View",
            "authorHandle": "quantview",
            "text": "Cross-asset reactions suggest markets are still sensitive to policy surprises.",
            "publishedAt": now - timedelta(hours=20),
            "themeName": "Markets and macro",
            "reason": "Strengthens the macro narrative across the snapshot.",
            "entryType": "post",
            "isReply": False,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "8",
            "authorName": "Launch Radar",
            "authorHandle": "launchradar",
            "text": "New tooling releases are creating another burst of AI product conversation.",
            "publishedAt": now - timedelta(hours=28),
            "themeName": "AI product launches",
            "reason": "Adds depth to the AI launch theme in the wider feed window.",
            "entryType": "reply",
            "isReply": True,
            "isAd": False,
            "isRepost": False,
            "isQuotePost": False,
        },
        {
            "id": "9",
            "authorName": "Strategy Stack",
            "authorHandle": "strategystack",
            "text": "More operators are sharing playbooks on distribution and go-to-market execution.",
            "publishedAt": now - timedelta(hours=34),
            "themeName": "Startup and builder commentary",
            "reason": "Rounds out the builder commentary theme in the wider batch.",
            "entryType": "ad",
            "isReply": False,
            "isAd": True,
            "isRepost": False,
            "isQuotePost": False,
        },
    ]

def clean_feed_items(feed_items: list[dict]) -> dict:
    cleaned_items = []
    excluded_reply_count = 0
    excluded_ad_count = 0
    excluded_other_count = 0

    for item in feed_items:
        if item["isAd"]:
            excluded_ad_count += 1            
            continue

        if item["isReply"]:
            excluded_reply_count += 1            
            continue

        if item["entryType"] not in {"post", "repost", "quote_post"}:
            excluded_other_count += 1
            continue

        cleaned_items.append(item)

    return {
        "items": cleaned_items,
        "excludedReplyCount": excluded_reply_count,
        "excludedAdCount": excluded_ad_count,
        "excludedOtherCount": excluded_other_count
    }

def build_theme_summary(feed_items: list[dict]) -> list[dict]:
    theme_counts: dict[str, int] = {}

    for item in feed_items:
        theme_name = item["themeName"]
        theme_counts[theme_name] = theme_counts.get(theme_name, 0) + 1

    total_items = len(feed_items)
    themes = []

    for theme_name, count in sorted(theme_counts.items(), key=lambda pair: pair[1], reverse=True):
        percentage = round((count / total_items) * 100, 1) if total_items > 0 else 0.0
        themes.append(
            {
                "name": theme_name,
                "count": count,
                "percentage": percentage,
            }
        )

    return themes


def build_notable_items(feed_items: list[dict], limit: int) -> list[dict]:
    items = []

    for item in feed_items[:limit]:
        items.append(
            {
                "id": item["id"],
                "authorName": item["authorName"],
                "authorHandle": item["authorHandle"],
                "text": item["text"],
                "reason": item["reason"],
                "url": None,
                "publishedAt": iso_z(item["publishedAt"]),
                "themeName": item["themeName"],
            }
        )

    return items


def build_fake_summary(request: XSummaryRequest) -> dict:
    now = datetime.now(timezone.utc)

    if request.timeWindowHours is None:
        window_hours = 36
    else:
        window_hours = request.timeWindowHours

    feed_window_end = now
    feed_window_start = now - timedelta(hours=window_hours)

    raw_feed_items = get_fake_feed_items(now)
    cleaning_result = clean_feed_items(raw_feed_items)
    cleaned_feed_items = cleaning_result["items"]

    filtered_feed_items = [
        item for item in cleaned_feed_items if item["publishedAt"] >= feed_window_start
    ]
    filtered_feed_items = filtered_feed_items[:request.maxItems]

    total_analysed_items = len(filtered_feed_items)
    themes = build_theme_summary(filtered_feed_items)

    if request.maxItems <= 20:
        headline_suffix = "The snapshot is narrower because you requested a smaller batch."
        notable_item_limit = 1
    else:
        headline_suffix = "AI, markets, and tech product chatter are dominating your feed today."
        notable_item_limit = 2

    notable_items = build_notable_items(filtered_feed_items, notable_item_limit)

    weighted_mean_time = feed_window_end - timedelta(hours=window_hours * 0.35)

    return {
        "summaryType": "digest",
        "generatedAt": iso_z(now),
        "feedWindowStart": iso_z(feed_window_start),
        "feedWindowEnd": iso_z(feed_window_end),
        "weightedMeanTime": iso_z(weighted_mean_time),
        "totalRawItems": len(raw_feed_items),
        "totalCleanedItems": len(cleaned_feed_items),
        "excludedReplyCount": cleaning_result["excludedReplyCount"],
        "excludedAdCount": cleaning_result["excludedAdCount"],
        "excludedOtherCount": cleaning_result["excludedOtherCount"],
        "totalAnalysedItems": total_analysed_items,
        "headline": f"Digest for {request.userId}: {headline_suffix}",
        "themes": themes,
        "notableItems": notable_items,
    }


@app.post("/x-summary")
def x_summary(request: XSummaryRequest):
    if not request.userId.strip():
        return JSONResponse(
            status_code=400,
            content={
                "errorCode": "invalid_user_id",
                "message": "userId is missing or blank.",
                "retryable": False,
                "requestId": "backend-validation-001"
            }
        )

    if request.maxItems <= 0 or request.maxItems > 100:
        return JSONResponse(
            status_code=400,
            content={
                "errorCode": "invalid_max_items",
                "message": "maxItems must be between 1 and 100.",
                "retryable": False,
                "requestId": "backend-validation-002"
            }
        )

    if request.summaryType != "digest":
        return JSONResponse(
            status_code=400,
            content={
                "errorCode": "unsupported_summary_type",
                "message": "summaryType must be 'digest' for v1.",
                "retryable": False,
                "requestId": "backend-validation-003"
            }
        )

    if request.timeWindowHours is not None:
        if request.timeWindowHours <= 0 or request.timeWindowHours > 168:
            return JSONResponse(
                status_code=400,
                content={
                    "errorCode": "invalid_time_window_hours",
                    "message": "timeWindowHours must be between 1 and 168 when provided.",
                    "retryable": False,
                    "requestId": "backend-validation-004"
                }
            )

    return build_fake_summary(request)