#!/usr/bin/python3
"""Waits for the newest uploaded build to finish processing, sets its "What to Test" (en-US/ko) and makes
sure the internal TestFlight group "Internal" exists with access to all builds (re-runnable).
Adding testers to the group is done on the App Store Connect website.
ASC=<compiled _tools/asc.swift> tools/asc_testflight.py
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_setup import api, rel, APP  # noqa: E402

WHAT_TO_TEST = {
    "en-US": "First test build. The AI check server is not live yet, so tapping \"Check it\" shows an error for now. "
             "Please try onboarding (with its built-in sample), the daily quiz, Learn, Family, History, Settings, "
             "large text mode, and the paywall (sandbox purchase, Restore Purchases).",
    "ko": "첫 테스트 빌드입니다. AI 확인 서버가 아직 준비되지 않아 지금은 \"확인하기\"를 누르면 오류가 나옵니다. "
          "온보딩(내장 샘플 체험), 매일 퀴즈, 배우기, 가족, 기록, 설정, 큰 글자 모드, "
          "구독 화면(샌드박스 구매, 구매 복원)을 확인해 주세요.",
}

for _ in range(60):
    builds = api("GET", f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=1")["data"]
    if builds and builds[0]["attributes"]["processingState"] != "PROCESSING":
        break
    time.sleep(30)
build = builds[0]
state = build["attributes"]["processingState"]
print("build", build["attributes"]["version"], state)
if state != "VALID":
    sys.exit("build is not VALID")

locs = api("GET", f"/v1/builds/{build['id']}/betaBuildLocalizations")["data"]
for loc, text in WHAT_TO_TEST.items():
    cur = next((l for l in locs if l["attributes"]["locale"] == loc), None)
    if cur:
        api("PATCH", f"/v1/betaBuildLocalizations/{cur['id']}", {"data": {"type": "betaBuildLocalizations",
            "id": cur["id"], "attributes": {"whatsNew": text}}})
    else:
        api("POST", "/v1/betaBuildLocalizations", {"data": {"type": "betaBuildLocalizations",
            "attributes": {"locale": loc, "whatsNew": text}, "relationships": {"build": rel("builds", build["id"])}}})
print("what to test: ok")

groups = api("GET", f"/v1/apps/{APP}/betaGroups")["data"]
group = next((g for g in groups if g["attributes"]["name"] == "Internal"), None)
if not group:
    group = api("POST", "/v1/betaGroups", {"data": {"type": "betaGroups",
        "attributes": {"name": "Internal", "isInternalGroup": True, "hasAccessToAllBuilds": True},
        "relationships": {"app": rel("apps", APP)}}})["data"]
print("beta group Internal", group["id"], "all builds:", group["attributes"].get("hasAccessToAllBuilds"))
