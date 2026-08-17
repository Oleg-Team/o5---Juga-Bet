import Foundation
import Combine

struct Player: Identifiable, Hashable {
    let id: UUID
    var name: String
    var score: Int

    init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}

enum Intensity: String, CaseIterable, Identifiable {
    case rookie
    case pro
    case legend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rookie: return "Rookie"
        case .pro: return "Pro"
        case .legend: return "Legend"
        }
    }

    var subtitle: String {
        switch self {
        case .rookie: return "Warm-up truths & light dares"
        case .pro: return "Game-day heat"
        case .legend: return "Championship pressure"
        }
    }

    var symbol: String {
        switch self {
        case .rookie: return "figure.walk"
        case .pro: return "figure.run"
        case .legend: return "trophy.fill"
        }
    }
}

enum PromptKind: String {
    case truth
    case dare

    var title: String { rawValue.uppercased() }

    var symbol: String {
        switch self {
        case .truth: return "text.bubble.fill"
        case .dare: return "bolt.fill"
        }
    }
}

struct Prompt: Identifiable, Equatable {
    let id: String
    let kind: PromptKind
    let intensity: Intensity
    let sport: String
    let text: String
}

@MainActor
final class GameStore: ObservableObject {
    @Published var players: [Player] = [
        Player(name: "Player 1"),
        Player(name: "Player 2")
    ]
    @Published var intensity: Intensity = .pro
    @Published var currentIndex: Int = 0
    @Published var roundCount: Int = 0
    @Published var usedPromptIDs: Set<String> = []
    @Published var overtimeUnlocked: Bool = UserDefaults.standard.bool(forKey: "overtimeUnlocked")
    @Published var lastPrompt: Prompt?

    var currentPlayer: Player {
        guard players.indices.contains(currentIndex) else {
            return Player(name: "Player")
        }
        return players[currentIndex]
    }

    func addPlayer() {
        guard players.count < 10 else { return }
        players.append(Player(name: "Player \(players.count + 1)"))
    }

    func removePlayer(_ player: Player) {
        guard players.count > 2 else { return }
        players.removeAll { $0.id == player.id }
        if currentIndex >= players.count {
            currentIndex = 0
        }
    }

    func canStart() -> Bool {
        players.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count >= 2
    }

    func resetMatch() {
        currentIndex = 0
        roundCount = 0
        usedPromptIDs.removeAll()
        lastPrompt = nil
        players = players.map { Player(id: $0.id, name: $0.name, score: 0) }
    }

    func drawPrompt(kind: PromptKind) -> Prompt {
        let pool = PromptBank.all.filter { prompt in
            prompt.kind == kind &&
            prompt.intensity == intensity &&
            !usedPromptIDs.contains(prompt.id)
        }

        let selected: Prompt
        if let pick = pool.randomElement() {
            selected = pick
        } else {
            usedPromptIDs = usedPromptIDs.filter { id in
                !PromptBank.all.contains { $0.id == id && $0.kind == kind && $0.intensity == intensity }
            }
            selected = PromptBank.all.filter { $0.kind == kind && $0.intensity == intensity }.randomElement()
                ?? PromptBank.all.filter { $0.kind == kind }.randomElement()!
        }

        usedPromptIDs.insert(selected.id)
        lastPrompt = selected
        return selected
    }

    func completeCurrent() {
        if players.indices.contains(currentIndex) {
            players[currentIndex].score += 1
        }
        advanceTurn()
    }

    func skipCurrent() {
        advanceTurn()
    }

    private func advanceTurn() {
        roundCount += 1
        currentIndex = (currentIndex + 1) % max(players.count, 1)
        lastPrompt = nil
    }

    func unlockOvertime() {
        overtimeUnlocked = true
        UserDefaults.standard.set(true, forKey: "overtimeUnlocked")
        intensity = .legend
    }
}
