#!/usr/bin/python3
"""Creates ScamSense's subscriptions in App Store Connect (idempotent: skips what already exists).

"ScamSense Pro" group: yearly (1-week free trial) and monthly, en-US/ko names, US/KR prices,
sold in USA/KOR/CAN, and a price in every other territory too (Apple's equalization of the USA price):
App Store Connect only accepts a subscription for review once all territories have a price.
Needs the compiled ASC client: swiftc -O -o <bin> _tools/asc.swift ; ASC=<bin> tools/asc_setup.py
Uses /usr/bin/python3 (standard library only). Adapted from daily_trio/tools/asc_setup.py.
"""
import json, os, subprocess, sys, time

ASC = os.environ.get("ASC", "")
APP = "6828638422"
TERRITORIES = ["USA", "KOR", "CAN"]
GROUP = "ScamSense Pro"
GROUP_NAMES = {"en-US": "ScamSense Pro", "ko": "스캠센스 Pro"}
PRICES = {  # product -> {territory: customer price}; CAN and the rest follow USA through Apple's equalization
    "com.namu3gru.ScamSense.pro.yearly": {"USA": "29.99", "KOR": "44000"},
    "com.namu3gru.ScamSense.pro.monthly": {"USA": "4.99", "KOR": "6900"},
}
FEATURES = {"en-US": "Unlimited checks, full history, family warnings",   # <= 55 characters
            "ko": "무제한 확인, 전체 기록, 가족 경고 메시지"}
SUBS = [  # productId, reference name, period, level, en name, ko name
    ("com.namu3gru.ScamSense.pro.yearly", "ScamSense Pro Yearly", "ONE_YEAR", 1, "ScamSense Pro Yearly", "스캠센스 Pro 연간"),
    ("com.namu3gru.ScamSense.pro.monthly", "ScamSense Pro Monthly", "ONE_MONTH", 2, "ScamSense Pro Monthly", "스캠센스 Pro 월간"),
]


def api(method, path, body=None):
    args = [ASC, method, path] + ([json.dumps(body)] if body is not None else [])
    for attempt in range(8):  # the API key is shared with other apps' scripts: back off on 429 / 5xx / network
        r = subprocess.run(args, capture_output=True, text=True)
        status = int(r.stderr.split()[1]) if r.stderr.startswith("HTTP") else 0
        try:
            data = json.loads(r.stdout) if r.stdout.strip() else {}
        except ValueError:
            data, status = {}, status or 0
            if status < 400:
                status = 0
        if status not in (0, 429) and status < 500:
            break
        time.sleep(20 * (attempt + 1))
    if status >= 400 or status == 0:
        sys.exit(f"{method} {path} -> {status}\n{r.stdout[:2000]}{r.stderr[:500]}")
    return data


def rel(type_, id_):
    return {"data": {"type": type_, "id": id_}}


def all_pages(path):
    out = []
    while path:
        d = api("GET", path)
        out += d["data"]
        nxt = d.get("links", {}).get("next")
        path = nxt.replace("https://api.appstoreconnect.apple.com", "") if nxt else None
    return out


def price_point(product_id, territory, price):
    """Finds the subscription price point id with this exact customer price."""
    for p in all_pages(f"/v1/subscriptions/{product_id}/pricePoints?filter[territory]={territory}&limit=200"):
        if float(p["attributes"]["customerPrice"]) == float(price):
            return p["id"]
    sys.exit(f"no {territory} price point {price} for {product_id}")


def set_prices(sid, pid, only_missing=False):
    usa = price_point(sid, "USA", PRICES[pid]["USA"])
    points = {"USA": usa, "KOR": price_point(sid, "KOR", PRICES[pid]["KOR"])}
    for eq in all_pages(f"/v1/subscriptionPricePoints/{usa}/equalizations?include=territory&limit=200"):
        points.setdefault(eq["relationships"]["territory"]["data"]["id"], eq["id"])
    done = set()
    if only_missing:  # resume after an interrupted run
        done = {p["relationships"]["territory"]["data"]["id"]
                for p in all_pages(f"/v1/subscriptions/{sid}/prices?include=territory&limit=200")}
    for terr, pp in points.items():
        if terr in done:
            continue
        api("POST", "/v1/subscriptionPrices", {"data": {"type": "subscriptionPrices",
            "attributes": {"preserveCurrentPrice": False},
            "relationships": {"subscription": rel("subscriptions", sid), "territory": rel("territories", terr),
                              "subscriptionPricePoint": rel("subscriptionPricePoints", pp)}}})
    return points


def main():
    for f in FEATURES.values():
        assert len(f) <= 55, f
    groups = api("GET", f"/v1/apps/{APP}/subscriptionGroups")["data"]
    group = next((g for g in groups if g["attributes"]["referenceName"] == GROUP), None)
    if not group:
        group = api("POST", "/v1/subscriptionGroups", {"data": {"type": "subscriptionGroups",
            "attributes": {"referenceName": GROUP}, "relationships": {"app": rel("apps", APP)}}})["data"]
        for loc, name in GROUP_NAMES.items():
            api("POST", "/v1/subscriptionGroupLocalizations", {"data": {"type": "subscriptionGroupLocalizations",
                "attributes": {"locale": loc, "name": name},
                "relationships": {"subscriptionGroup": rel("subscriptionGroups", group["id"])}}})
    print("group", group["id"])

    existing = {s["attributes"]["productId"]: s for s in api("GET", f"/v1/subscriptionGroups/{group['id']}/subscriptions")["data"]}
    for pid, ref, period, level, en, ko in SUBS:
        sub = existing.get(pid)
        resume = sub is not None  # created by an earlier, interrupted run: fill in what's missing
        if not sub:
            sub = api("POST", "/v1/subscriptions", {"data": {"type": "subscriptions",
                "attributes": {"name": ref, "productId": pid, "subscriptionPeriod": period, "groupLevel": level,
                               "familySharable": False},
                "relationships": {"group": rel("subscriptionGroups", group["id"])}}})["data"]
        sid = sub["id"]
        have = {l["attributes"]["locale"] for l in api("GET", f"/v1/subscriptions/{sid}/subscriptionLocalizations")["data"]}
        for loc, name in (("en-US", en), ("ko", ko)):
            if loc in have:
                continue
            api("POST", "/v1/subscriptionLocalizations", {"data": {"type": "subscriptionLocalizations",
                "attributes": {"locale": loc, "name": name, "description": FEATURES[loc]},
                "relationships": {"subscription": rel("subscriptions", sid)}}})
        if not (resume and api("GET", f"/v1/subscriptions/{sid}/subscriptionAvailability").get("data")):
            api("POST", "/v1/subscriptionAvailabilities", {"data": {"type": "subscriptionAvailabilities",
                "attributes": {"availableInNewTerritories": False},
                "relationships": {"subscription": rel("subscriptions", sid),
                                  "availableTerritories": {"data": [{"type": "territories", "id": t} for t in TERRITORIES]}}}})
        points = set_prices(sid, pid, only_missing=resume)
        offers = set()
        if resume:
            offers = {o["relationships"]["territory"]["data"]["id"]
                      for o in api("GET", f"/v1/subscriptions/{sid}/introductoryOffers?include=territory")["data"]}
        if period == "ONE_YEAR":
            for terr in [t for t in TERRITORIES if t not in offers]:
                api("POST", "/v1/subscriptionIntroductoryOffers", {"data": {"type": "subscriptionIntroductoryOffers",
                    "attributes": {"duration": "ONE_WEEK", "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                    "relationships": {"subscription": rel("subscriptions", sid), "territory": rel("territories", terr)}}})
        print("resumed" if resume else "created", pid, sid, len(points), "territory prices")


if __name__ == "__main__":
    main()
