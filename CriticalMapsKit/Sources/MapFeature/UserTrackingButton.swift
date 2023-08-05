import ComposableArchitecture
import L10n
import MapKit
import SwiftUI
import SwiftUIHelpers

/// Button to toggle tracking modes
public struct UserTrackingButton: View {
  public typealias State = UserTrackingFeature.State
  public typealias Action = UserTrackingFeature.Action

  let store: Store<State, Action>
  @ObservedObject var viewStore: ViewStore<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  public var body: some View {
    Button(
      action: {
        viewStore.send(.nextTrackingMode)
      },
      label: {
        iconImage
      }
    )
    .accessibility(label: Text(viewStore.mode.accessiblityLabel))
    .accessibilityAction(named: Text(L10n.A11y.Usertrackingbutton.hint)) {
      viewStore.send(.nextTrackingMode)
    }
    .accessibilityHint(Text(L10n.A11y.Usertrackingbutton.hint))
    .accessibilityShowsLargeContentViewer {
      Label(viewStore.mode.accessiblityLabel, systemImage: "location.fill")
    }
  }

  var iconImage: some View {
    switch viewStore.mode {
    case .follow:
      return Image(systemName: "location.fill")
        .iconModifier()
    case .followWithHeading:
      return Image(systemName: "location.north.line.fill")
        .iconModifier()
    case .none:
      return Image(systemName: "location")
        .iconModifier()
    @unknown default:
      return Image(systemName: "location")
        .iconModifier()
    }
  }
}

// MARK: Preview

struct UserTrackingButton_Previews: PreviewProvider {
  static var previews: some View {
    Preview {
      Group {
        UserTrackingButton(
          store: .init(initialState: .init(userTrackingMode: .none)) {
            UserTrackingFeature()._printChanges()
          }
        )
        
        UserTrackingButton(
          store: .init(initialState: .init(userTrackingMode: .follow)) {
            UserTrackingFeature()._printChanges()
          }
        )
        
        UserTrackingButton(
          store: .init(initialState: .init(userTrackingMode: .followWithHeading)) {
            UserTrackingFeature()._printChanges()
          }
        )
      }
    }
  }
}
