import ComposableArchitecture
import L10n
import SharedModels
import Styleguide
import SwiftUI
import SwiftUIHelpers

/// A view to render next ride event settings
public struct RideEventSettingsView: View {
  public typealias State = RideEventSettings
  public typealias Action = RideEventsSettingsFeature.Action
  
  let store: Store<State, Action>
  @ObservedObject var viewStore: ViewStore<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
    viewStore = ViewStore(store)
  }

  public var body: some View {
    SettingsForm {
      Spacer(minLength: 28)

      SettingsRow {
        HStack {
          Toggle(
            isOn: viewStore.binding(
              get: \.isEnabled,
              send: Action.setRideEventsEnabled
            ),
            label: { Text(L10n.Settings.eventSettingsEnable) }
          )
          .accessibilityRepresentation(representation: {
            viewStore.isEnabled
              ? Text(L10n.A11y.General.on)
              : Text(L10n.A11y.General.off)
          })
        }
        .accessibilityElement(children: .combine)
      }
      ZStack(alignment: .top) {
        VStack {
          SettingsSection(title: L10n.Settings.eventTypes) {
            ForEach(viewStore.typeSettings, id: \.type.title) { rideType in
              SettingsRow {
                Button(
                  action: { viewStore.send(
                    .setRideEventTypeEnabled(
                      .init(
                        type: rideType.type,
                        isEnabled: !rideType.isEnabled
                      )
                    )
                  )
                  },
                  label: {
                    RideEventSettingsRow(
                      title: rideType.type.title,
                      isEnabled: rideType.isEnabled
                    )
                  }
                )
              }
              .accessibilityValue(rideType.isEnabled ? Text(L10n.A11y.General.selected) : Text(""))
            }
          }

          SettingsSection(title: L10n.Settings.eventSearchRadius) {
            ForEach(EventDistance.allCases, id: \.self) { radius in
              SettingsRow {
                Button(
                  action: { viewStore.send(.setRideEventRadius(radius)) },
                  label: {
                    HStack(spacing: .grid(3)) {
                      Text(String(radius.displayValue))
                        .accessibility(label: Text(radius.accessibilityLabel))
                        .padding(.vertical, .grid(2))
                      Spacer()
                      if viewStore.eventDistance == radius {
                        Image(systemName: "checkmark.circle.fill")
                          .accessibilityRepresentation {
                            Text(L10n.A11y.General.selected)
                          }
                      }
                    }
                    .accessibilityElement(children: .combine)
                  }
                )
              }
            }
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: viewStore.isEnabled ? .none : 0)
        .clipped()
        .accessibleAnimation(.interactiveSpring(), value: viewStore.isEnabled)
      }
      .foregroundColor(Color(.textPrimary))
      .disabled(!viewStore.isEnabled)
    }
    .navigationBarTitle(L10n.Settings.eventSettings, displayMode: .inline)
  }
}

// MARK: Preview

struct RideEventSettings_Previews: PreviewProvider {
  static var previews: some View {
    Preview {
      NavigationView {
        RideEventSettingsView(
          store: .init(
            initialState: .init(
              isEnabled: true,
              typeSettings: .all,
              eventDistance: .near
            ),
            reducer: RideEventsSettingsFeature().debug()
          )
        )
      }
    }
  }
}

// MARK: Helper

struct RideEventSettingsRow: View {
  let title: String
  let isEnabled: Bool

  var body: some View {
    HStack(spacing: .grid(3)) {
      Text(title)
        .padding(.vertical, .grid(2))
      Spacer()
      if isEnabled {
        Image(systemName: "checkmark.circle.fill")
      } else {
        Image(systemName: "circle")
      }
    }
  }
}
