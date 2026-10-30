#!/usr/bin/python3
"""Waits for the newest uploaded build to finish processing, sets its "What to Test" (en-US/ko) and makes
sure the internal TestFlight group "Internal" exists with access to all builds (re-runnable).
Adding testers to the group is done on the App Store Connect website.
ASC=<compiled _tools/asc.swift> tools/asc_testflight.py [build number]
Also attaches the build to version 1.0 when that version is still being prepared.
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_setup import api, rel, APP  # noqa: E402

WHAT_TO_TEST = {
    "en-US": "This build talks to the live ScamSense server: your free-check count and subscriptions are checked there. "
             "The AI itself is not switched on yet, so \"Check it\" still shows an error until it is (it won't use up a free check). "
             "Please try onboarding (built-in sample), the daily quiz, Learn, Family, History, Settings, large text mode, "
             "and the paywall: sandbox purchase with the 1-week free trial, then Restore Purchases.",
    "ko": "이번 빌드는 실제 스캠센스 서버에 연결됩니다. 남은 무료 횟수와 구독 확인은 서버에서 합니다. "
          "AI는 아직 켜지지 않아 \"확인하기\"는 당분간 오류가 나옵니다(무료 횟수는 차감되지 않아요). "
          "온보딩(내장 샘플), 매일 퀴즈, 배우기, 가족, 기록, 설정, 큰 글자 모드, "
          "구독 화면(1주 무료 체험 샌드박스 구매 후 구매 복원)을 확인해 주세요.",
}

for _ in range(60):
    builds = api("GET", f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=1")["data"]
    if len(sys.argv) > 1 and (not builds or builds[0]["attributes"]["version"] != sys.argv[1]):
        builds = []  # the build given on the command line hasn't shown up yet
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

versions = api("GET", f"/v1/apps/{APP}/appStoreVersions")["data"]
v = next((v for v in versions if v["attributes"]["versionString"] == "1.0"
          and v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"), None)
if v:
    api("PATCH", f"/v1/appStoreVersions/{v['id']}/relationships/build", {"data": {"type": "builds", "id": build["id"]}})
    print("attached to version 1.0")
