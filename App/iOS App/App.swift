import AppFeature
import BackgroundTasks
import ComposableArchitecture
import SwiftUI
import UIKit

@main
struct CriticalMapsApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @Environment(\.scenePhase) var scenePhase

  init() {}

  var body: some Scene {
    WindowGroup {
      AppView(store: self.appDelegate.store)
    }
    .onChange(of: scenePhase) { _ in
//      self.appDelegate.viewStore.send(.)
    }
  }
}

// MARK: AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {
  let store = Store(initialState: .init()) {
    AppFeature()
  }
  
  lazy var viewStore: ViewStore<Void, AppFeature.Action> = ViewStore(
    self.store,
    observe: { _ in },
    removeDuplicates: ==
  )

  func application(
    _ application: UIApplication,
    // swiftlint:disable:next discouraged_optional_collection
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    viewStore.send(.appDelegate(.didFinishLaunching))
    return true
  }
}
