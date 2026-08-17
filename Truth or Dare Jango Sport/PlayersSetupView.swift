import SwiftUI

struct PlayersSetupView: View {
    @EnvironmentObject private var store: GameStore
    @FocusState private var focusedID: UUID?
    @State private var goToMatch = false

    var body: some View {
        ZStack {
            SportPitchBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("LINE-UP")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(AppTheme.accent)

                    Text("Who is playing?")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.text)

                    VStack(spacing: 10) {
                        ForEach($store.players) { $player in
                            HStack(spacing: 12) {
                                Text(jerseyNumber(for: player.id))
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(width: 42, height: 42)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(AppTheme.accent)
                                    )

                                TextField("Player name", text: $player.name)
                                    .focused($focusedID, equals: player.id)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.text)
                                    .tint(AppTheme.accent)

                                if store.players.count > 2 {
                                    Button {
                                        store.removePlayer(player)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.card.opacity(0.85))
                            )
                        }
                    }

                    Button {
                        store.addPlayer()
                    } label: {
                        Label("Add player", systemImage: "plus")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                            )
                    }
                    .disabled(store.players.count >= 10)

                    Text("INTENSITY")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        ForEach(Intensity.allCases) { item in
                            intensityCard(item)
                        }
                    }

                    Button {
                        store.resetMatch()
                        goToMatch = true
                    } label: {
                        Label("Kick Off", systemImage: "flag.checkered")
                    }
                    .buttonStyle(GlowButtonStyle())
                    .disabled(!store.canStart())
                    .opacity(store.canStart() ? 1 : 0.45)
                    .padding(.top, 8)
                    .navigationDestination(isPresented: $goToMatch) {
                        GameView()
                    }
                }
                .padding(22)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func jerseyNumber(for id: UUID) -> String {
        let index = (store.players.firstIndex(where: { $0.id == id }) ?? 0) + 1
        return String(format: "%02d", index)
    }

    private func intensityCard(_ item: Intensity) -> some View {
        let selected = store.intensity == item
        return Button {
            store.intensity = item
        } label: {
            VStack(spacing: 8) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .bold))
                Text(item.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(selected ? AppTheme.ink : AppTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AppTheme.accent : AppTheme.card)
            )
        }
        .buttonStyle(.plain)
    }
}
