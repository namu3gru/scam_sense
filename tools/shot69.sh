#!/bin/sh
# Usage: U=<simulator udid> tools/shot69.sh <lang en|ko> <name> [launch args...]
# 6.9" App Store screenshots (1320x2868) on an iPhone 17 Pro Max simulator -> screenshots/appstore/raw/<lang>_<name>.png
# Uses the built-in demo data (-uiDemo) and an unreachable server, so nothing goes over the network.
: "${U:?set U to your iPhone 17 Pro Max simulator UDID}"
B=com.namu3gru.ScamSense
L=$1; NAME=$2; shift 2
OUT="$(dirname "$0")/../screenshots/appstore/raw/${L}_$NAME.png"
mkdir -p "$(dirname "$OUT")"
if [ "$L" = ko ]; then LA="-AppleLanguages (ko) -AppleLocale ko_KR -uiCountry KR"; else LA="-AppleLanguages (en) -AppleLocale en_US -uiCountry US"; fi
xcrun simctl terminate $U $B >/dev/null 2>&1
xcrun simctl launch $U $B $LA -uiReset YES -uiOnboarded YES -uiConsent YES -uiDemo YES \
  -apiBaseURL http://127.0.0.1:9 -uiConfirmClear NO -uiRestore NO -uiNoBanner YES "$@" >/dev/null
sleep ${WAIT:-6}
# A busy Mac can still show the white launch screen (~90 KB PNG): retake until the app has drawn.
for _ in 1 2 3 4 5 6 7 8 9 10; do
  xcrun simctl io $U screenshot "$OUT" >/dev/null 2>&1
  [ "$(stat -f %z "$OUT")" -gt 150000 ] && break
  sleep 4
done
[ -n "${SETTLE:-}" ] && { sleep $SETTLE; xcrun simctl io $U screenshot "$OUT" >/dev/null 2>&1; }
echo "$OUT"
