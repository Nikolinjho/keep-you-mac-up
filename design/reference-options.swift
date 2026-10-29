import AppKit
func label(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, bold: Bool = false) {
    (value as NSString).draw(at: NSPoint(x:x,y:y), withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:bold ? .semibold:.regular),.foregroundColor:NSColor.black])
}
let entries = [("1 · Noun Project", "Kelig Le Luron", "noun-38379.png"), ("2 · Noun Project", "Gisela Leyva", "noun-808358.png"), ("3 · Icons8", "Those Icons", "icons8-macbook.jpg")]
let canvas = NSImage(size:NSSize(width:1050,height:410),flipped:false) { rect in
    NSColor.white.setFill();rect.fill()
    label("Варианты из твоих подборок",32,356,28,bold:true)
    label("Оригинальные превью. Ниже каждого – размер 22 × 22 для строки меню.",32,323,16)
    for (index, entry) in entries.enumerated() {
        let x = CGFloat(40 + index*345)
        label(entry.0,x,280,21,bold:true)
        let image = NSImage(contentsOfFile:"design/references/"+entry.2)!
        image.draw(in:NSRect(x:x+50,y:90,width:170,height:170))
        image.draw(in:NSRect(x:x+122,y:49,width:22,height:22))
        label(entry.1,x+50,16,15)
    }
    return true
}
let bitmap = NSBitmapImageRep(data:canvas.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"design/reference-options.png"))
