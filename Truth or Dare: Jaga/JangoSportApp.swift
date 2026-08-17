import SwiftUI

@main
struct JangoSportApp: App {
    init() {
        _ = GrayLogicO1MEFUCJEFC.shared
        AdsManager.shared.bootstrap()

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.text)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.text)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.accent)
        UITextField.appearance().keyboardAppearance = .dark
    }

    var body: some Scene {
        WindowGroup {
            ContentViewO1MEFUCJEFC()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentViewO1MEFUCJEFC: View {
    @State var showLoadingO1MEFUCJEFC = true

    var body: some View {
        ZStack {
            if showLoadingO1MEFUCJEFC {
                LoadingViewO1MEFUCJEFC(showView: $showLoadingO1MEFUCJEFC)
            } else {
                RootViewO1MEFUCJEFC()
            }
        }
    }
}

struct RootViewO1MEFUCJEFC: View {
    @StateObject private var store = GameStore()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environmentObject(store)
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentViewO1MEFUCJEFC()
}
