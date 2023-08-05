import ComposableArchitecture
import L10n
import SharedModels
import Styleguide
import SwiftUI

/// A view to render appearance settings.
public struct AppearanceSettingsView: View {
  public typealias State = AppearanceSettings
  public typealias Action = AppearanceSettingsFeature.Action

  let store: Store<State, Action>
  @ObservedObject var viewStore: ViewStore<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  public var body: some View {
    SettingsForm {
      SettingsSection(title: "Theme") {
        Picker("", selection: viewStore.binding(get: \.colorScheme, send: { .set(\.$colorScheme, $0) })) {
          ForEach(AppearanceSettings.ColorScheme.allCases, id: \.self) {
            Text($0.title)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(height: 50)
        .padding(.horizontal, .grid(4))

        SettingsSection(title: L10n.Settings.appIcon) {
          AppIconPicker(appIcon: viewStore.binding(get: \.appIcon, send: { .set(\.$appIcon, $0) }))
        }
      }
    }
    .foregroundColor(Color(.textPrimary))
    .navigationBarTitle(L10n.Settings.Theme.appearance, displayMode: .inline)
  }
}

// AppIcon grid view
struct AppIconPicker: View {
  @Binding var appIcon: AppIcon

  var body: some View {
    VStack(spacing: .grid(2)) {
      ForEach(Array(AppIcon.allCases.enumerated()), id: \.element) { _, appIcon in
        SettingsRow {
          Button(
            action: { self.appIcon = appIcon },
            label: {
              HStack(spacing: .grid(3)) {
                Image(uiImage: appIcon.image)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 48, height: 48)
                  .continuousCornerRadius(12)
                  .id(appIcon)
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color(.textPrimary), lineWidth: 0.4)
                  )

                Text(appIcon.title)

                Spacer()

                if self.appIcon == appIcon {
                  Image(systemName: "checkmark.circle.fill")
                    .accessibilityRepresentation { Text(L10n.A11y.General.selected) }
                }
              }
              .accessibilityElement(children: .combine)
            }
          )
        }
      }
    }
  }
}

extension AppearanceSettings.ColorScheme {
  var title: String {
    switch self {
    case .system:
      return L10n.Settings.Theme.system
    case .light:
      return L10n.Settings.Theme.light
    case .dark:
      return L10n.Settings.Theme.dark
    }
  }
}

extension AppIcon {
  var image: UIImage {
    UIImage(named: rawValue, in: .module, with: nil)!
  }

  var title: String {
    switch self {
    case .appIcon1:
      return "Dark"
    case .appIcon2:
      return "Light"
    case .appIcon3:
      return "Neon"
    case .appIcon4:
      return "Rainbow"
    case .appIcon5:
      return "Yellow"
    }
  }
}
