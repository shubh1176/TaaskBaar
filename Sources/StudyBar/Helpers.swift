import SwiftUI

// MARK: - Color Palette
extension Color {
    static let sbAccent = Color.orange
    static let sbBackground = Color(NSColor.controlBackgroundColor)
    static let sbSecondaryBackground = Color(NSColor.controlBackgroundColor.withSystemEffect(.pressed))
    static let sbText = Color(NSColor.labelColor)
    static let sbSecondaryText = Color(NSColor.secondaryLabelColor)
    static let sbTertiaryText = Color(NSColor.tertiaryLabelColor)

    static let sbGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let sbOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
    static let sbRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let sbBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let sbPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let sbTeal = Color(red: 0.2, green: 0.7, blue: 0.7)
    static let sbPink = Color(red: 0.9, green: 0.3, blue: 0.5)
    static let sbYellow = Color(red: 0.9, green: 0.7, blue: 0.1)
}

// MARK: - Formatting Extensions
extension Int {
    var formattedTime: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedHours: String {
        let hours = Double(self) / 3600.0
        return String(format: "%.1f", hours)
    }
}

extension Double {
    var formattedHours: String {
        String(format: "%.1f", self)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isPast: Bool {
        self < Date()
    }
}

// MARK: - View Modifier
struct CardStyle: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func sbButton(_ color: Color = .blue, compact: Bool = false) -> some View {
        modifier(SBButtonStyle(color: color, compact: compact))
    }

    func sbIconButton() -> some View {
        modifier(SBIconButtonStyle())
    }
}

struct SBButtonStyle: ViewModifier {
    var color: Color
    var compact: Bool
    @State private var hovered = false

    func body(content: Content) -> some View {
        content
            .font(.system(size: compact ? 11 : 12, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 5 : 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovered ? color.opacity(0.12) : color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(color.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .scaleEffect(hovered ? 1.03 : 1)
            .shadow(color: hovered ? color.opacity(0.15) : .clear, radius: 3, y: 1)
            .onHover { h in withAnimation(.spring(response: 0.25)) { hovered = h } }
            .animation(.spring(response: 0.25), value: hovered)
    }
}

struct SBIconButtonStyle: ViewModifier {
    @State private var hovered = false

    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(hovered ? .primary : .secondary)
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovered ? Color.gray.opacity(0.15) : Color.clear)
            )
            .scaleEffect(hovered ? 1.05 : 1)
            .onHover { h in withAnimation(.spring(response: 0.25)) { hovered = h } }
    }
}

// MARK: - Haptic Feedback
struct Haptics {
    static func tap() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }

    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }

    static func error() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
}

// MARK: - SF Symbol Helper
enum SBIcon: String {
    case dashboard = "square.grid.2x2"
    case tasks = "checklist"
    case timer = "timer"
    case flashcards = "rectangle.stack"
    case revisions = "arrow.triangle.2.circlepath"
    case exams = "calendar.badge.clock"
    case distractions = "eye.slash"
    case sessions = "book.closed"
    case quickCapture = "bolt"
    case settings = "gearshape"
    case streak = "flame"
    case focus = "target"
    case add = "plus.circle.fill"
    case done = "checkmark.circle.fill"
    case empty = "tray"

    var image: Image { Image(systemName: rawValue) }
}

// MARK: - Date+Relative
extension Date {
    func daysFromNow() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }

    func daysBetween(_ other: Date) -> Int {
        abs(Calendar.current.dateComponents([.day], from: self, to: other).day ?? 0)
    }

    var weekdaySymbol: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    var shortDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
}

// MARK: - Chart Shapes

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        )
        var path = Path()
        path.move(to: center)
        path.addLine(to: start)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct DonutChart: View {
    var segments: [(value: Double, color: Color, label: String)]
    var innerRadiusRatio: CGFloat = 0.6
    var animated: Bool = true

    @State private var animProgress: CGFloat = 0

    var total: Double { segments.map(\.value).reduce(0, +) }

    var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { idx in
                let seg = segments[idx]
                let start = segments[0..<idx].map(\.value).reduce(0, +) / total * 360
                let end = start + (seg.value / total * 360) * Double(animProgress)
                PieSlice(
                    startAngle: .degrees(start - 90),
                    endAngle: .degrees(end - 90)
                )
                .fill(seg.color)
            }
            Circle()
                .fill(.regularMaterial)
                .scaleEffect(innerRadiusRatio)
        }
        .onAppear {
            if animated {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                    animProgress = 1
                }
            } else {
                animProgress = 1
            }
        }
    }
}

struct BarChart: View {
    var data: [(label: String, value: Double, color: Color)]
    var maxValue: Double?
    var barSpacing: CGFloat = 4
    var barRadius: CGFloat = 4

    @State private var animProgress: CGFloat = 0

    private var maxVal: Double { maxValue ?? data.map(\.value).max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(0..<data.count, id: \.self) { idx in
                let item = data[idx]
                let height = maxVal > 0 ? (item.value / maxVal) * 80 : 0
                VStack(spacing: 3) {
                    Text("\(Int(item.value))h")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(item.value > 0 ? 1 : 0)
                    RoundedRectangle(cornerRadius: barRadius, style: .continuous)
                        .fill(item.color.gradient)
                        .frame(height: max(CGFloat(height) * animProgress, 0))
                        .frame(maxWidth: 20)
                        .shadow(color: item.color.opacity(0.3), radius: 2, y: 1)
                    Text(item.label)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 110)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                animProgress = 1
            }
        }
    }
}

struct RingProgress: View {
    var progress: Double
    var color: Color = .orange
    var lineWidth: CGFloat = 8
    var glow: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: glow ? color.opacity(0.5) : .clear, radius: glow ? 8 : 0)
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

// MARK: - Interactive Card Modifier
struct InteractiveCard: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1)
            .onHover { hovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func interactiveCard() -> some View {
        modifier(InteractiveCard())
    }
}
