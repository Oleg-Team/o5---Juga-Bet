import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var activePrompt: Prompt?
    @State private var flipping = false
    @State private var showSkipConfirm = false

    var body: some View {
        ZStack {
            SportPitchBackground()

            VStack(spacing: 16) {
                header

                if let prompt = activePrompt {
                    CardRevealView(prompt: prompt, playerName: store.currentPlayer.name)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))

                    HStack(spacing: 12) {
                        Button {
                            showSkipConfirm = true
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.muted.opacity(0.35), lineWidth: 1)
                                )
                        }

                        Button {
                            completeRound()
                        } label: {
                            Label("Done", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(GlowButtonStyle())
                    }
                    .padding(.horizontal, 20)
                } else {
                    Spacer()
                    choiceBoard
                    Spacer()
                }

                BannerAdView()
                    .frame(width: 320, height: 50)
                    .padding(.bottom, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("MATCHDAY")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .confirmationDialog("Skip this challenge?", isPresented: $showSkipConfirm, titleVisibility: .visible) {
            Button("Watch ad to skip") {
                AdsManager.shared.showRewarded { success in
                    if success {
                        skipRound()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Watch a rewarded video to skip without losing the round.")
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: activePrompt)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("NOW PLAYING")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(AppTheme.muted)

            Text(store.currentPlayer.name)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.players) { player in
                        let active = player.id == store.currentPlayer.id
                        HStack(spacing: 6) {
                            Circle()
                                .fill(active ? AppTheme.accent : AppTheme.muted.opacity(0.4))
                                .frame(width: 7, height: 7)
                            Text(player.name)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text("\(player.score)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(active ? AppTheme.ink : AppTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(active ? AppTheme.accent : AppTheme.card))
                        }
                        .foregroundStyle(active ? AppTheme.text : AppTheme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(active ? AppTheme.navyMid : AppTheme.card.opacity(0.7))
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }

    private var choiceBoard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                choiceButton(kind: .truth)
                choiceButton(kind: .dare)
            }

            Button {
                let kind: PromptKind = Bool.random() ? .truth : .dare
                draw(kind)
            } label: {
                Label("Random", systemImage: "shuffle")
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .padding(.horizontal, 20)
    }

    private func choiceButton(kind: PromptKind) -> some View {
        Button {
            draw(kind)
        } label: {
            VStack(spacing: 14) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 30, weight: .bold))
                Text(kind.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(kind == .truth ? AppTheme.truth : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(kind == .truth ? AppTheme.card : AppTheme.accent)
                    .shadow(color: (kind == .dare ? AppTheme.accent : AppTheme.truth).opacity(0.28), radius: 18, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(kind == .truth ? AppTheme.truth.opacity(0.35) : Color.clear, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func draw(_ kind: PromptKind) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        activePrompt = store.drawPrompt(kind: kind)
    }

    private func completeRound() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        store.completeCurrent()
        activePrompt = nil
        AdsManager.shared.showInterstitialIfNeeded(afterRound: store.roundCount)
    }

    private func skipRound() {
        store.skipCurrent()
        activePrompt = nil
        AdsManager.shared.showInterstitialIfNeeded(afterRound: store.roundCount)
    }
}

struct CardRevealView: View {
    let prompt: Prompt
    let playerName: String
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(prompt.kind.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.accent))

                Text(prompt.sport.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.muted)

                Spacer()

                Text(prompt.intensity.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }

            Text("\(playerName),")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.muted)

            Text(prompt.text)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.card.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: AppTheme.accent.opacity(0.18), radius: 24, y: 10)
        )
        .padding(.horizontal, 20)
        .rotation3DEffect(.degrees(appeared ? 0 : 90), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}
