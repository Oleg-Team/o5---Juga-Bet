import SwiftUI
import WebKit

struct LoadingViewO1MEFUCJEFC: View {
    @AppStorage("urlString") var urlString = ""
    @Binding var showView: Bool

    var grayO1MEFUCJEFC = GrayLogicO1MEFUCJEFC.shared

    var body: some View {
        ZStack {
            if !urlString.isEmpty && urlString != "error" {
                webView(url: urlString)
            } else {
                AppLoadingViewO1MEFUCJEFC()
            }
        }
        .onAppear {
            guard urlString == "error" else { return }
            closeLoading()
        }
        .onChange(of: urlString) { _, newValue in
            guard newValue == "error" else { return }
            closeLoading()
        }
    }

    func closeLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showView = false
            }
        }
    }

    func webView(url: String) -> some View {
        WebViewCont(urlString: url)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .padding(.top, 7)
            .padding(.bottom, 1)
            .background(Color.black)
    }
}

struct AppLoadingViewO1MEFUCJEFC: View {
    @State private var pulse = false
    @State private var ring: CGFloat = 0

    var body: some View {
        ZStack {
            SportPitchBackground()

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.18), lineWidth: 6)
                        .frame(width: 148, height: 148)
                    Circle()
                        .trim(from: 0, to: ring)
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "soccerball")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                }

                VStack(spacing: 8) {
                    Text("JANGO SPORT")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text("Lacing up the match...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2)) {
                ring = 1
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct WebViewCont: UIViewRepresentable {
    var urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false

        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] result, _ in
            if let currentUserAgent = result as? String {
                webView?.customUserAgent = currentUserAgent + " Safari/604.1"
            }
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: "\(urlString)") {
            DispatchQueue.main.async {
                let request = URLRequest(url: url)
                uiView.allowsBackForwardNavigationGestures = true
                uiView.load(request)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewCont

        init(_ parent: WebViewCont) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let finalURL = webView.url {
                guard !finalURL.absoluteString.contains("file://"),
                      UserDefaults.standard.bool(forKey: "redirection") else { return }

                if finalURL.absoluteString == "https://www.apple.com/en/app-store/" {
                    UserDefaults.standard.set("error", forKey: "urlString")
                    UserDefaults.standard.set(false, forKey: "redirection")
                    return
                }

                UserDefaults.standard.set(finalURL.absoluteString, forKey: "urlString")
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            let newWebView = WKWebView(frame: webView.frame, configuration: configuration)
            newWebView.customUserAgent = webView.customUserAgent
            newWebView.navigationDelegate = self
            newWebView.uiDelegate = self
            newWebView.allowsBackForwardNavigationGestures = true

            let newWebViewController = UIViewController()
            newWebViewController.view = newWebView

            if let currentWindow = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .filter(\.isKeyWindow).first,
               let currentViewController = currentWindow.rootViewController {
                currentViewController.present(newWebViewController, animated: true)
            }

            return newWebView
        }

        func webViewDidClose(_ webView: WKWebView) {
            webView.removeFromSuperview()
        }
    }
}
