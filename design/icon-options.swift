import AppKit

func icon(_ style: Int, active: Bool) -> NSImage {
    NSImage(size: NSSize(width: 24, height: 20), flipped: false) { _ in
        NSColor.black.set()
        switch style {
        case 0:
            let screen = NSBezierPath(roundedRect: NSRect(x: 3, y: 5, width: 18, height: 12), xRadius: 2, yRadius: 2)
            screen.lineWidth = 1.4
            screen.stroke()
            if active { NSBezierPath(roundedRect: NSRect(x: 5, y: 7, width: 14, height: 8), xRadius: 0.6, yRadius: 0.6).fill() }
            let base = NSBezierPath()
            base.move(to: NSPoint(x: 1, y: 3.5)); base.line(to: NSPoint(x: 23, y: 3.5))
            base.line(to: NSPoint(x: 21, y: 2)); base.line(to: NSPoint(x: 3, y: 2)); base.close(); base.fill()
        case 1:
            let screen = NSBezierPath(roundedRect: NSRect(x: 3.5, y: 4.5, width: 17, height: 12.5), xRadius: 1, yRadius: 1)
            screen.lineWidth = 1.3; screen.stroke()
            if active { NSBezierPath(rect: NSRect(x: 5.1, y: 6.1, width: 13.8, height: 9.3)).fill() }
            let base = NSBezierPath()
            base.move(to: NSPoint(x: 3, y: 4)); base.line(to: NSPoint(x: 1, y: 1.8))
            base.line(to: NSPoint(x: 23, y: 1.8)); base.line(to: NSPoint(x: 21, y: 4))
            base.lineWidth = 1.2; base.stroke()
        case 2:
            let screen = NSBezierPath(roundedRect: NSRect(x: 3, y: 5, width: 18, height: 12), xRadius: 1.1, yRadius: 1.1)
            screen.lineWidth = 1; screen.stroke()
            if active { NSBezierPath(roundedRect: NSRect(x: 4.3, y: 6.3, width: 15.4, height: 9.4), xRadius: 0.3, yRadius: 0.3).fill() }
            let base = NSBezierPath()
            base.move(to: NSPoint(x: 0.5, y: 3)); base.line(to: NSPoint(x: 23.5, y: 3))
            base.lineWidth = 1.1; base.lineCapStyle = .round; base.stroke()
        default:
            let screen = NSBezierPath(roundedRect: NSRect(x: 2, y: 6, width: 20, height: 12), xRadius: 1.5, yRadius: 1.5)
            screen.lineWidth = 1.3; screen.stroke()
            if active { NSBezierPath(roundedRect: NSRect(x: 3.7, y: 9, width: 16.6, height: 7.3), xRadius: 0.3, yRadius: 0.3).fill() }
            NSBezierPath(rect: NSRect(x: 10, y: 2.5, width: 4, height: 3)).fill()
            let base = NSBezierPath(roundedRect: NSRect(x: 7, y: 1, width: 10, height: 1.4), xRadius: 0.7, yRadius: 0.7)
            base.fill()
        }
        return true
    }
}

func text(_ string: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor = .black, weight: NSFont.Weight = .regular) {
    (string as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color
    ])
}

let canvas = NSImage(size: NSSize(width: 1000, height: 680), flipped: false) { bounds in
    NSColor(calibratedWhite: 0.98, alpha: 1).setFill(); bounds.fill()
    text("Выбери значок KeepYouAwake", x: 40, y: 619, size: 29, weight: .semibold)
    text("Слева увеличенный значок, справа его размер в строке меню", x: 40, y: 586, size: 16, color: .darkGray)
    text("Выключено", x: 440, y: 537, size: 17, color: .darkGray)
    text("Включено", x: 720, y: 537, size: 17, color: .darkGray)
    let titles = ["1 · Скруглённый", "2 · Классический", "3 · Тонкий", "4 · iMac"]
    for index in 0..<4 {
        let y = CGFloat(438 - index * 116)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: NSRect(x: 24, y: y - 13, width: 952, height: 100), xRadius: 12, yRadius: 12).fill()
        text(titles[index], x: 48, y: y + 24, size: 23, weight: .medium)
        for (active, x) in [(false, CGFloat(440)), (true, CGFloat(720))] {
            let image = icon(index, active: active)
            image.draw(in: NSRect(x: x, y: y + 4, width: 72, height: 60))
            image.draw(in: NSRect(x: x + 116, y: y + 24, width: 24, height: 20))
        }
    }
    return true
}
let bitmap = NSBitmapImageRep(data: canvas.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "design/icon-options.png"))
