#!/usr/bin/python3
"""Fills ScamSense's App Store listing for version 1.0 through the App Store Connect API (re-runnable).

Text comes from README.md section 7/8 (en-US + ko), screenshots from screenshots/appstore/{en,ko}/.
Also: category, age rating, content rights, copyright, review contact + notes, free price,
US/KR/CA availability, the newest processed build, and paywall review screenshots for the subscriptions.
Left for the App Store Connect website: App Privacy answers and Submit for Review
(attach the subscription group and each subscription there). Adapted from daily_trio/tools/asc_metadata.py.
ASC=<compiled _tools/asc.swift> tools/asc_metadata.py
"""
import hashlib, json, os, re, sys, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_setup import api, rel, all_pages, APP, GROUP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TERRITORIES = ["USA", "KOR", "CAN"]
readme = open(os.path.join(ROOT, "README.md"), encoding="utf-8").read()


def section(title_regex, end_regex):
    return re.search(title_regex + r"(.*?)" + end_regex, readme, re.S).group(1)


en_block = section(r"### English \(U\.S\.\)", r"### 한국어")
ko_block = section(r"### 한국어", r"## 8\.")
review_notes = re.search(r"```\n(.*?)\n```", section(r"## 8\.", r"## 9\."), re.S).group(1).strip()


def fields(block, names):
    out = {}
    for key, label in names.items():
        out[key] = re.search(r"- \*\*" + label + r"[^*]*\*\*:? ?(.*)", block).group(1).strip().strip("`")
    out["description"] = re.search(r"```\n(.*?)\n```", block, re.S).group(1).strip()
    return out


EN = fields(en_block, {"name": "Name", "subtitle": "Subtitle", "keywords": "Keywords", "promo": "Promotional text"})
KO = fields(ko_block, {"name": "이름", "subtitle": "부제", "keywords": "키워드", "promo": "프로모션 텍스트"})
for loc, f in (("en-US", EN), ("ko", KO)):
    assert len(f["name"]) <= 30 and len(f["subtitle"]) <= 30 and len(f["keywords"]) <= 100 \
        and len(f["promo"]) <= 170 and len(f["description"]) <= 4000, (loc, {k: len(v) for k, v in f.items()})
PRIVACY = "https://scamsense.namu3gru.com/privacy"
SUPPORT = "https://scamsense.namu3gru.com/support"
for f in (EN, KO):  # App Store Connect rejects emoji in the description
    assert not [c for c in f["description"] if ord(c) > 0xFFFF], "emoji in description"


def upsert(kind, parent_rel, parent_type, parent_id, existing, locale, attrs):
    """Creates or updates a localization of `kind` for `locale`."""
    cur = next((x for x in existing if x["attributes"]["locale"] == locale), None)
    if cur:
        api("PATCH", f"/v1/{kind}/{cur['id']}", {"data": {"type": kind, "id": cur["id"], "attributes": attrs}})
        return cur["id"]
    return api("POST", f"/v1/{kind}", {"data": {"type": kind, "attributes": {"locale": locale, **attrs},
                                                "relationships": {parent_rel: rel(parent_type, parent_id)}}})["data"]["id"]


def upload_asset(create_path, rel_name, rel_type, rel_id, kind, path):
    """App Store Connect asset upload: reserve, PUT the parts, commit with an MD5 checksum."""
    data = open(path, "rb").read()
    res = api("POST", create_path, {"data": {"type": kind,
        "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {rel_name: rel(rel_type, rel_id)}}})["data"]
    for op in res["attributes"]["uploadOperations"]:
        req = urllib.request.Request(op["url"], data=data[op["offset"]:op["offset"] + op["length"]], method=op["method"])
        for h in op.get("requestHeaders", []):
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req, timeout=120).read()
    api("PATCH", f"/v1/{kind}/{res['id']}", {"data": {"type": kind, "id": res["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return res["id"]


# --- App info: name, subtitle, privacy URL, category, age rating --------------------------------
info = api("GET", f"/v1/apps/{APP}/appInfos")["data"][0]
info_locs = api("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]
for loc, f in (("en-US", EN), ("ko", KO)):
    upsert("appInfoLocalizations", "appInfo", "appInfos", info["id"], info_locs, loc,
           {"name": f["name"], "subtitle": f["subtitle"], "privacyPolicyUrl": PRIVACY})
api("PATCH", f"/v1/appInfos/{info['id']}", {"data": {"type": "appInfos", "id": info["id"], "relationships": {
    "primaryCategory": rel("appCategories", "UTILITIES"),
    "secondaryCategory": rel("appCategories", "LIFESTYLE")}}})
age = api("GET", f"/v1/appInfos/{info['id']}/ageRatingDeclaration")["data"]
# Scam-awareness content with no violence, sexual, drug, gambling or horror themes; no ads, no chat between
# users, no unrestricted web browser (links open in Safari only when tapped), nothing shared publicly -> 4+.
LEVELS = ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "gunsOrOtherWeapons",
          "medicalOrTreatmentInformation", "profanityOrCrudeHumor", "sexualContentGraphicAndNudity",
          "sexualContentOrNudity", "horrorOrFearThemes", "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
          "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic"]
FLAGS = ["advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat", "parentalControls",
         "ageAssurance", "socialMedia", "socialMediaAgeRestricted", "unrestrictedWebAccess", "userGeneratedContent"]
none_attrs = {**{k: "NONE" for k in LEVELS}, **{k: False for k in FLAGS}}
api("PATCH", f"/v1/ageRatingDeclarations/{age['id']}", {"data": {"type": "ageRatingDeclarations", "id": age["id"], "attributes": none_attrs}})
api("PATCH", f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP,
    "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})
print("app info, category, age rating, content rights: ok")

# --- Version 1.0: texts, copyright, review details, build ----------------------------------------
version = next(v for v in api("GET", f"/v1/apps/{APP}/appStoreVersions")["data"] if v["attributes"]["versionString"] == "1.0")
vid = version["id"]
api("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid,
    "attributes": {"copyright": "2026 Janghyun Lee", "releaseType": "AFTER_APPROVAL"}}})
ver_locs = api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]
loc_ids = {}
for loc, f in (("en-US", EN), ("ko", KO)):
    loc_ids[loc] = upsert("appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", vid, ver_locs, loc,
                          {"description": f["description"], "keywords": f["keywords"],
                           "promotionalText": f["promo"], "supportUrl": SUPPORT})
review = {"contactFirstName": "Janghyun", "contactLastName": "Lee", "contactPhone": "+1 947 948 5814",
          "contactEmail": "support@namu3gru.com", "demoAccountRequired": False, "notes": review_notes}
detail = api("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail").get("data")
if detail:
    api("PATCH", f"/v1/appStoreReviewDetails/{detail['id']}", {"data": {"type": "appStoreReviewDetails", "id": detail["id"], "attributes": review}})
else:
    api("POST", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": review,
        "relationships": {"appStoreVersion": rel("appStoreVersions", vid)}}})
builds = api("GET", f"/v1/builds?filter[app]={APP}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")["data"]
build = builds[0]
api("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": build["id"]}})
print("version texts, review details: ok; build", build["attributes"]["version"])

# --- Price (free) and availability ---------------------------------------------------------------
free = next(p for p in all_pages(f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=200")
            if float(p["attributes"]["customerPrice"]) == 0)
api("POST", "/v1/appPriceSchedules", {
    "data": {"type": "appPriceSchedules", "relationships": {
        "app": rel("apps", APP), "baseTerritory": rel("territories", "USA"),
        "manualPrices": {"data": [{"type": "appPrices", "id": "${free}"}]}}},
    "included": [{"type": "appPrices", "id": "${free}", "attributes": {"startDate": None},
                  "relationships": {"appPricePoint": rel("appPricePoints", free["id"])}}]})
# Availability must list every territory, each marked available or not.
all_terr = [t["id"] for t in all_pages("/v1/territories?limit=200")]
try:
    api("POST", "/v2/appAvailabilities", {
        "data": {"type": "appAvailabilities", "attributes": {"availableInNewTerritories": False},
                 "relationships": {"app": rel("apps", APP), "territoryAvailabilities": {"data": [
                     {"type": "territoryAvailabilities", "id": f"${{{t}}}"} for t in all_terr]}}},
        "included": [{"type": "territoryAvailabilities", "id": f"${{{t}}}", "attributes": {"available": t in TERRITORIES},
                      "relationships": {"territory": rel("territories", t)}} for t in all_terr]})
    print("price free, availability", TERRITORIES, "of", len(all_terr))
except SystemExit as e:
    print("availability not set (already exists?):", str(e)[:600])

# --- Screenshots (6.9" = APP_IPHONE_67), replaced on each run -----------------------------------
for loc, folder in (("en-US", "en"), ("ko", "ko")):
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_ids[loc]}/appScreenshotSets")["data"]
    s = next((x for x in sets if x["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
    if s:
        for shot in api("GET", f"/v1/appScreenshotSets/{s['id']}/appScreenshots")["data"]:
            api("DELETE", f"/v1/appScreenshots/{shot['id']}")
    else:
        s = api("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
            "relationships": {"appStoreVersionLocalization": rel("appStoreVersionLocalizations", loc_ids[loc])}}})["data"]
    files = sorted(f for f in os.listdir(os.path.join(ROOT, "screenshots/appstore", folder)) if f.endswith(".jpg"))
    for f in files:
        upload_asset("/v1/appScreenshots", "appScreenshotSet", "appScreenshotSets", s["id"], "appScreenshots",
                     os.path.join(ROOT, "screenshots/appstore", folder, f))
    print("screenshots", loc, len(files))

# --- Paywall screenshot for each product's review ------------------------------------------------
paywall = os.path.join(ROOT, "screenshots/appstore/raw/en_paywall.png")  # tools/shot69.sh en paywall -uiScreen paywall
group = next(g for g in api("GET", f"/v1/apps/{APP}/subscriptionGroups")["data"] if g["attributes"]["referenceName"] == GROUP)
for sub in api("GET", f"/v1/subscriptionGroups/{group['id']}/subscriptions")["data"]:
    if not api("GET", f"/v1/subscriptions/{sub['id']}/appStoreReviewScreenshot").get("data"):
        upload_asset("/v1/subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions", sub["id"],
                     "subscriptionAppStoreReviewScreenshots", paywall)
print("product review screenshots: ok")
