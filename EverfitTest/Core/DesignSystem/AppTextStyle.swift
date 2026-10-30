import CoreText
import SwiftUI

/// A Figma text style in Open Sans: weight, size, line height and letter spacing.
/// Apply with `.textStyle(_:)` so line height and letter spacing are honoured, not just the font.
struct AppTextStyle {
    let size: CGFloat
    /// `.regular` (400) or `.bold` (700); each needs its `OpenSans-<Weight>.ttf` in `Resources/Fonts`.
    let weight: Font.Weight
    /// Figma line height in points (100% = `size`); `nil` = Figma "Auto" (the font's natural height).
    let lineHeight: CGFloat?
    /// Figma letter spacing in points.
    let letterSpacing: CGFloat
    /// Figma Layout › Height of a fixed-height text layer, when taller than the line; the text sits at its top.
    let layoutHeight: CGFloat?

    init(
        size: CGFloat,
        weight: Font.Weight,
        lineHeight: CGFloat? = nil,
        letterSpacing: CGFloat = 0,
        layoutHeight: CGFloat? = nil
    ) {
        self.size = size
        self.weight = weight
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.layoutHeight = layoutHeight
    }

    var font: Font {
        _ = BundledFonts.register
        return .custom(postScriptName, fixedSize: size)
    }

    /// Line height minus the font's natural height (ascent + descent + leading); 0 for "Auto".
    /// Negative when the line height is tighter than the font.
    var lineHeightAdjustment: CGFloat {
        guard let lineHeight else { return 0 }
        _ = BundledFonts.register
        let ctFont = CTFontCreateWithName(postScriptName as CFString, size, nil)
        return lineHeight - (CTFontGetAscent(ctFont) + CTFontGetDescent(ctFont) + CTFontGetLeading(ctFont))
    }

    private var postScriptName: String {
        weight == .bold ? "OpenSans-Bold" : "OpenSans-Regular"
    }
}

extension View {
    /// Font, letter spacing, Figma line height and (optional) fixed layer height. Like Figma, the line box
    /// grows or shrinks by the same amount above and below the text; extra space also goes between wrapped lines.
    func textStyle(_ style: AppTextStyle) -> some View {
        let adjustment = style.lineHeightAdjustment
        return font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(max(0, adjustment))
            .padding(.vertical, adjustment / 2)
            .frame(height: style.layoutHeight, alignment: .top)
    }
}

/// Registers every `.ttf` in the app bundle once, so no Info.plist `UIAppFonts` entry is needed.
private enum BundledFonts {
    static let register: Void = {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
