import AppKit
// Captioned App Store screenshots (1320x2868): caption on deep navy above a rounded, shadowed screenshot.
// JPEG output: App Store screenshots must not carry an alpha channel.
// Usage (from scam_sense/): swift tools/frame_shots.swift   (reads screenshots/appstore/raw, writes screenshots/appstore/<lang>/)
let W = 1320.0, H = 2868.0
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let raw = root.appendingPathComponent("screenshots/appstore/raw")
let shots: [(String, [String: (String, String)])] = [
    ("1_check",   ["en": ("Is it a scam?\nCheck before you tap", "Paste a text, link or screenshot"),
                   "ko": ("사기일까?\n누르기 전에 확인", "문자·링크·스크린샷을 붙여 넣기만")]),
    ("2_result",  ["en": ("A clear answer\nin plain words", "Red, amber or green, with the reasons"),
                   "ko": ("쉬운 말로\n한눈에 판정", "빨강·노랑·초록 신호등과 이유")]),
    ("3_actions", ["en": ("Know what to do\nnext", "Even if you already clicked or paid"),
                   "ko": ("지금 무엇을\n해야 할지", "이미 눌렀거나 돈을 보냈을 때도")]),
    ("4_quiz",    ["en": ("Spot the scam:\na daily quiz", "Five real-looking messages a day"),
                   "ko": ("매일 5문제\n사기 찾기 퀴즈", "진짜 같은 메시지로 연습")]),
    ("5_history", ["en": ("Your checks stay\non your iPhone", "No account, no ads, no tracking"),
                   "ko": ("확인 기록은\n내 iPhone에만", "회원가입·광고·추적 없음")]),
    ("6_learn",   ["en": ("Learn today's\nbiggest scams", "12 short, plain-language guides"),
                   "ko": ("요즘 사기 수법\n미리 알아두기", "쉽게 정리한 12가지 수법")]),
    ("7_family",  ["en": ("Protect the people\nyou love", "Safety habits and ready-made warnings"),
                   "ko": ("부모님과 가족을\n함께 지켜요", "안전 습관과 바로 보내는 경고")]),
]
let navy = NSColor(red: 0x11/255.0, green: 0x1B/255.0, blue: 0x4D/255.0, alpha: 1)
let gold = NSColor(red: 0xF5/255.0, green: 0xB8/255.0, blue: 0x3D/255.0, alpha: 1)
for lang in ["en", "ko"] {
    let outDir = root.appendingPathComponent("screenshots/appstore/\(lang)")
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    for (i, (name, caps)) in shots.enumerated() {
        guard let shot = NSImage(contentsOf: raw.appendingPathComponent("\(lang)_\(name).png")) else { fatalError("\(lang)_\(name)") }
        let (title, sub) = caps[lang]!
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: W, height: H)
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let bg = NSGradient(starting: navy, ending: NSColor(red: 0x23/255.0, green: 0x40/255.0, blue: 0x9F/255.0, alpha: 1))!
        bg.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
        let p = NSMutableParagraphStyle(); p.alignment = .center; p.lineHeightMultiple = 0.98
        let t = NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: lang == "ko" ? 104 : 108, weight: .heavy),
                                                               .foregroundColor: NSColor.white, .paragraphStyle: p])
        let tr = t.boundingRect(with: NSSize(width: W - 120, height: 600), options: [.usesLineFragmentOrigin])
        let top = H - 150
        t.draw(with: NSRect(x: 60, y: top - tr.height, width: W - 120, height: tr.height), options: [.usesLineFragmentOrigin])
        let s = NSAttributedString(string: sub, attributes: [.font: NSFont.systemFont(ofSize: 52, weight: .semibold),
                                                             .foregroundColor: gold, .paragraphStyle: p])
        s.draw(with: NSRect(x: 60, y: top - tr.height - 110, width: W - 120, height: 80), options: [.usesLineFragmentOrigin])
        let sw = W * 0.80, sh = sw * 2868 / 1320
        let box = NSRect(x: (W - sw) / 2, y: top - tr.height - 190 - sh, width: sw, height: sh)
        NSGraphicsContext.saveGraphicsState()
        let sh0 = NSShadow(); sh0.shadowBlurRadius = 60; sh0.shadowOffset = NSSize(width: 0, height: -20)
        sh0.shadowColor = NSColor.black.withAlphaComponent(0.45); sh0.set()
        NSColor.black.setFill(); NSBezierPath(roundedRect: box.insetBy(dx: -14, dy: -14), xRadius: 84, yRadius: 84).fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: box, xRadius: 70, yRadius: 70).addClip(); shot.draw(in: box); NSGraphicsContext.restoreGraphicsState()
        let out = outDir.appendingPathComponent(String(format: "%02d_%@.jpg", i + 1, String(name.split(separator: "_").last!)))
        try! rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])!.write(to: out)
        print(out.path)
    }
}
