import SwiftUI

/// Spacing scale, corner radii and component metrics.
/// `Calendar` paddings, column width and card spacing are Figma specs; `rowMinHeight`, `Radius.card`
/// and the check badge were measured from the screenshot.
enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24

    enum Radius {
        static let card: CGFloat = 8
    }

    /// Training calendar screen.
    enum Calendar {
        /// Day row inset: leading, top and bottom.
        static let rowPadding: CGFloat = 20
        /// Day row inset on the trailing side.
        static let rowTrailingPadding: CGFloat = 21
        /// Height of a row with no or one workout.
        static let rowMinHeight: CGFloat = 112
        static let dividerHeight: CGFloat = 1
        /// Weekday/day column, labels left-aligned.
        static let dateColumnWidth: CGFloat = 46
        /// Gap between the date column and the workout cards.
        static let dateToCardsSpacing: CGFloat = 8
        /// "MON" (20pt line) sits just above the card title's line, "20" (24pt line) on the subtitle's line, as in Figma.
        static let dateTopInset: CGFloat = 13
        static let dateLabelSpacing: CGFloat = 0
        /// Vertical gap between stacked workout cards.
        static let cardSpacing: CGFloat = 8
        /// Workout card content inset.
        static let cardPadding = EdgeInsets(top: 16, leading: 16, bottom: 15, trailing: 18)
        static let cardTextSpacing: CGFloat = 3
        static let checkBadgeSize: CGFloat = 24
        static let checkBadgeTrailingInset: CGFloat = 8
    }
}
