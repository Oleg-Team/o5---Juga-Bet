import UIKit
import SwiftUI
import AppTrackingTransparency
import UnityAds

final class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    static let gameID = "800357227"
    static let rewardedPlacement = "Rewarded_iOS"
    static let interstitialPlacement = "Interstitial_iOS"
    static let bannerPlacement = "Banner_iOS"

    @Published var isInitialized = false
    @Published var rewardedReady = false
    @Published var interstitialReady = false

    private var rewardedAd: UADSRewardedAd?
    private var interstitialAd: UADSInterstitialAd?
    private var rewardedCompletion: ((Bool) -> Void)?
    private var interstitialCompletion: (() -> Void)?
    private lazy var rewardedProxy = RewardedShowProxy(owner: self)
    private lazy var interstitialProxy = InterstitialShowProxy(owner: self)

    func bootstrap() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.requestTrackingThenInitialize()
        }
    }

    private func requestTrackingThenInitialize() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                DispatchQueue.main.async {
                    self?.initializeSDK()
                }
            }
        } else {
            initializeSDK()
        }
    }

    private func initializeSDK() {
        let config = UADSInitializationConfigurationBuilder(gameId: Self.gameID)
            .with(testMode: false)
            .build()

        UnityAds.initialize(config) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.isInitialized = false
                    print("Unity Ads init failed: \(error)")
                    return
                }
                self?.isInitialized = true
                self?.preload()
            }
        }
    }

    func showInterstitialIfNeeded(afterRound round: Int, every n: Int = 3) {
        guard round > 0, round % n == 0 else { return }
        showInterstitial()
    }

    func showInterstitial(completion: (() -> Void)? = nil) {
        interstitialCompletion = completion
        guard let ad = interstitialAd, let vc = Self.topViewController() else {
            completion?()
            preloadInterstitial()
            return
        }
        let showConfig = UADSShowConfigurationBuilder()
            .with(viewController: vc)
            .build()
        ad.show(showConfig, delegate: interstitialProxy)
    }

    func showRewarded(completion: @escaping (Bool) -> Void) {
        rewardedCompletion = completion
        guard let ad = rewardedAd, let vc = Self.topViewController() else {
            completion(false)
            preloadRewarded()
            return
        }
        let showConfig = UADSShowConfigurationBuilder()
            .with(viewController: vc)
            .build()
        ad.show(showConfig, delegate: rewardedProxy)
    }

    func preload() {
        preloadRewarded()
        preloadInterstitial()
    }

    func preloadRewarded() {
        let config = UADSLoadConfigurationBuilder(placementId: Self.rewardedPlacement).build()
        UADSRewardedAd.load(config) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error {
                    self?.rewardedAd = nil
                    self?.rewardedReady = false
                    print("Rewarded load failed: \(error)")
                    return
                }
                self?.rewardedAd = ad
                self?.rewardedReady = ad != nil
                ad?.onAdExpired = { _ in
                    DispatchQueue.main.async {
                        self?.rewardedAd = nil
                        self?.rewardedReady = false
                        self?.preloadRewarded()
                    }
                }
            }
        }
    }

    func preloadInterstitial() {
        let config = UADSLoadConfigurationBuilder(placementId: Self.interstitialPlacement).build()
        UADSInterstitialAd.load(config) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error {
                    self?.interstitialAd = nil
                    self?.interstitialReady = false
                    print("Interstitial load failed: \(error)")
                    return
                }
                self?.interstitialAd = ad
                self?.interstitialReady = ad != nil
                ad?.onAdExpired = { _ in
                    DispatchQueue.main.async {
                        self?.interstitialAd = nil
                        self?.interstitialReady = false
                        self?.preloadInterstitial()
                    }
                }
            }
        }
    }

    fileprivate func rewardedDidFinish(success: Bool) {
        guard rewardedCompletion != nil else { return }
        rewardedCompletion?(success)
        rewardedCompletion = nil
        rewardedAd = nil
        rewardedReady = false
        preloadRewarded()
    }

    fileprivate func interstitialDidFinish() {
        interstitialCompletion?()
        interstitialCompletion = nil
        interstitialAd = nil
        interstitialReady = false
        preloadInterstitial()
    }

    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseController = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let nav = baseController as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseController as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = baseController?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseController
    }
}

private final class RewardedShowProxy: NSObject, UADSRewardedShowDelegate {
    weak var owner: AdsManager?

    init(owner: AdsManager) {
        self.owner = owner
    }

    func showDidStart(_ unityAd: UADSRewardedAd) {}
    func showDidClick(_ unityAd: UADSRewardedAd) {}

    func showDidComplete(_ unityAd: UADSRewardedAd, with finishState: UADSShowFinishState) {
        DispatchQueue.main.async {
            if finishState == .skipped {
                self.owner?.rewardedDidFinish(success: false)
            }
        }
    }

    func showDidFail(_ unityAd: UADSRewardedAd, error: any UnityAdsError) {
        DispatchQueue.main.async {
            self.owner?.rewardedDidFinish(success: false)
        }
    }

    func showDidReceiveReward(_ unityAd: UADSRewardedAd) {
        DispatchQueue.main.async {
            self.owner?.rewardedDidFinish(success: true)
        }
    }
}

private final class InterstitialShowProxy: NSObject, UADSInterstitialShowDelegate {
    weak var owner: AdsManager?

    init(owner: AdsManager) {
        self.owner = owner
    }

    func showDidStart(_ unityAd: UADSInterstitialAd) {}
    func showDidClick(_ unityAd: UADSInterstitialAd) {}

    func showDidComplete(_ unityAd: UADSInterstitialAd, with finishState: UADSShowFinishState) {
        DispatchQueue.main.async {
            self.owner?.interstitialDidFinish()
        }
    }

    func showDidFail(_ unityAd: UADSInterstitialAd, error: any UnityAdsError) {
        DispatchQueue.main.async {
            self.owner?.interstitialDidFinish()
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        container.backgroundColor = .clear
        context.coordinator.container = container

        let config = UADSBannerLoadConfigurationBuilder(
            placementId: AdsManager.bannerPlacement,
            bannerSize: CGSize(width: 320, height: 50),
            delegate: context.coordinator
        ).build()

        UADSBannerAd.load(config) { ad, error in
            DispatchQueue.main.async {
                if let error {
                    print("Unity banner load failed: \(error)")
                    return
                }
                guard let ad, let container = context.coordinator.container else { return }
                context.coordinator.bannerAd = ad
                ad.view.frame = container.bounds
                ad.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.addSubview(ad.view)
            }
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UADSBannerAdDelegate {
        var container: UIView?
        var bannerAd: UADSBannerAd?

        func bannerImpression(_ banner: UADSBannerAd) {}
        func bannerDidClick(_ banner: UADSBannerAd) {}
        func bannerDidFailShow(_ banner: UADSBannerAd, error: any UnityAdsError) {
            print("Unity banner show failed: \(error)")
        }
    }
}
