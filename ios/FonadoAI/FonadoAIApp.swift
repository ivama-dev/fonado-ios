import SwiftUI
import UIKit
import Intents
import CarPlay

/// Created before the first scene; a future PushKit cold start must not depend on a view.
@MainActor
final class FonadoAppDelegate: NSObject, UIApplicationDelegate {
    static weak var current: FonadoAppDelegate?
    let phone: PhoneStore = {
        #if DEBUG
        if TeamPreview.enabled { return PhoneStore(previewCore: TeamPreviewCore()) }
        #endif
        return PhoneStore()
    }()
    private lazy var callIntentHandler = FonadoCallIntentHandler(phone: phone)
    let customer: CustomerAccount = {
        #if DEBUG
        if TeamPreview.enabled { return CustomerAccount(teamPreview: true) }
        #endif
        return CustomerAccount()
    }()
    override init() {
        super.init()
        Self.current = self
        #if DEBUG
        if TeamPreview.enabled { return }
        #endif
        customer.attach(phone: phone)
    }
    // The CarPlay role is declared in CarPlay-Info.plist. Returning its delegate
    // through UIApplicationDelegateAdaptor wraps it in SwiftUI's scene delegate,
    // which does not implement CarPlay's interface-controller callbacks. UIKit
    // must instantiate the native CarPlay delegate directly from the manifest.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return phone.continueCallActivity(userActivity)
    }
    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        // Only the separate CarPlay configuration advertises this capability.
        guard Bundle.main.object(forInfoDictionaryKey: "fonadoCarPlayEnabled") as? Bool == true else { return nil }
        return intent is INStartCallIntent ? callIntentHandler : nil
    }
}

@main
@MainActor
struct FonadoAIApp: App {
    @UIApplicationDelegateAdaptor(FonadoAppDelegate.self) private var delegate
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            CustomerEntryView()
                .environmentObject(delegate.phone)
                .environmentObject(delegate.customer)
                #if DEBUG
                .safeAreaInset(edge: .bottom) {
                    if TeamPreview.enabled { Text("Vorschau · Beispieldaten").font(FonadoStyle.font(.caption)).foregroundStyle(.secondary).padding(8) }
                }
                #endif
                .tint(FonadoStyle.accent)
                .font(FonadoStyle.font(.body))
                .foregroundStyle(FonadoStyle.ink)
                .onChange(of: scenePhase, initial:true) { _, phase in
                    delegate.customer.setPresenceForeground(phase == .active)
                    if phase == .active { Task { await delegate.customer.refresh() } }
                }
                .onContinueUserActivity("INStartCallIntent") { activity in
                    delegate.phone.continueCallActivity(activity)
                }
                .onContinueUserActivity("INStartAudioCallIntent") { activity in
                    delegate.phone.continueCallActivity(activity)
                }
        }
    }
}
