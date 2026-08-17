import SwiftUI

enum AppTheme {
    static let navy = Color(red: 0 / 255, green: 28 / 255, blue: 76 / 255)
    static let navyDeep = Color(red: 0 / 255, green: 10 / 255, blue: 32 / 255)
    static let navyMid = Color(red: 8 / 255, green: 42 / 255, blue: 96 / 255)
    static let card = Color(red: 6 / 255, green: 36 / 255, blue: 86 / 255)
    static let accent = Color(red: 0 / 255, green: 230 / 255, blue: 118 / 255)
    static let accentDim = Color(red: 0 / 255, green: 200 / 255, blue: 83 / 255)
    static let ink = Color(red: 0 / 255, green: 18 / 255, blue: 48 / 255)
    static let text = Color(red: 244 / 255, green: 247 / 255, blue: 255 / 255)
    static let muted = Color(red: 139 / 255, green: 163 / 255, blue: 199 / 255)
    static let truth = Color(red: 124 / 255, green: 255 / 255, blue: 203 / 255)
    static let dare = Color(red: 0 / 255, green: 230 / 255, blue: 118 / 255)
}

struct SportPitchBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.navyDeep, AppTheme.navy, AppTheme.navyMid.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 42
                    var x: CGFloat = -geo.size.height
                    while x < geo.size.width + geo.size.height {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height))
                        x += spacing
                    }
                }
                .stroke(AppTheme.accent.opacity(0.06), lineWidth: 1.2)

                Circle()
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.45, y: -80)

                Circle()
                    .fill(AppTheme.navyMid.opacity(0.8))
                    .frame(width: 240, height: 240)
                    .blur(radius: 50)
                    .offset(x: -80, y: geo.size.height * 0.62)
            }
        }
        .ignoresSafeArea()
    }
}

struct GlowButtonStyle: ButtonStyle {
    var fill: Color = AppTheme.accent
    var foreground: Color = AppTheme.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .shadow(color: fill.opacity(configuration.isPressed ? 0.15 : 0.45), radius: configuration.isPressed ? 6 : 18, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.7), lineWidth: 1.4)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.card.opacity(0.55))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
