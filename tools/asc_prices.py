#!/usr/bin/python3
"""Re-prices ScamSense's subscriptions from asc_setup.PRICES (USA + KOR exact, every other territory
from Apple's equalization of the USA price). A new price without a start date replaces the current one
(current prices cannot be deleted). Edit PRICES in asc_setup.py first.
ASC=<compiled _tools/asc.swift> tools/asc_prices.py
"""
import sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from asc_setup import api, set_prices, APP, GROUP  # noqa: E402  (asc_setup only runs its setup under __main__)

group = next(g for g in api("GET", f"/v1/apps/{APP}/subscriptionGroups")["data"] if g["attributes"]["referenceName"] == GROUP)
for sub in api("GET", f"/v1/subscriptionGroups/{group['id']}/subscriptions")["data"]:
    pid, sid = sub["attributes"]["productId"], sub["id"]
    points = set_prices(sid, pid)
    shown = {t: api("GET", f"/v1/subscriptionPricePoints/{points[t]}")["data"]["attributes"]["customerPrice"]
             for t in ("USA", "KOR", "CAN")}
    print(pid, len(points), "territories", shown)
