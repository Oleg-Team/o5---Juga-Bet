import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showHowTo = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            SportPitchBackground()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.18), lineWidth: 2)
                        .frame(width: 168, height: 168)
                        .scaleEffect(pulse ? 1.08 : 0.96)

                    Circle()
                        .fill(AppTheme.navyMid)
                        .frame(width: 132, height: 132)
                        .shadow(color: AppTheme.accent.opacity(0.35), radius: 24)

                    Image(systemName: "soccerball")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(spacing: 8) {
                    Text("TRUTH OR DARE")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(AppTheme.muted)

                    Text("JANGO SPORT")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                        .shadow(color: AppTheme.accent.opacity(0.25), radius: 12)

                    Text("Sports confessions. Championship dares.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 28)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink {
                        PlayersSetupView()
                    } label: {
                        Label("Play Match", systemImage: "whistle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(GlowButtonStyle())

                    Button {
                        showHowTo = true
                    } label: {
                        Label("How to Play", systemImage: "sportscourt")
                    }
                    .buttonStyle(OutlineButtonStyle())

                    if !store.overtimeUnlocked {
                        Button {
                            AdsManager.shared.showRewarded { success in
                                if success {
                                    store.unlockOvertime()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text("Unlock Overtime Pack")
                            }
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlayView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.navyDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("How to Play")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.text)

                rule(icon: "person.3.fill", title: "Build the squad", text: "Add 2–10 players. Everyone takes a turn in order.")
                rule(icon: "text.bubble.fill", title: "Truth", text: "Answer a sports confession out loud. No skipping the honesty.")
                rule(icon: "bolt.fill", title: "Dare", text: "Complete a sports challenge in the room. Safe, loud, and competitive.")
                rule(icon: "play.rectangle.fill", title: "Skip a dare", text: "Watch a short rewarded ad to skip. Interstitials appear every few rounds.")

                Spacer()

                Button("Got it") { dismiss() }
                    .buttonStyle(GlowButtonStyle())
            }
            .padding(24)
        }
    }

    private func rule(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppTheme.card))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }
}
