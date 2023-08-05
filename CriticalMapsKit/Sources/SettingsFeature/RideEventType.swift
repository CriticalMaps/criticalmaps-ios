import ComposableArchitecture
import Foundation
import L10n
import SharedModels
import SwiftUI

public struct RideEventType: Reducer {
  public init() {}
  
  public struct State: Equatable, Identifiable, Sendable, Codable {
    public var id: String {
      self.rideType.rawValue
    }
    public let rideType: Ride.RideType
    @BindingState public var isEnabled = true
    
    public init(rideType: Ride.RideType, isEnabled: Bool) {
      self.rideType = rideType
      self.isEnabled = isEnabled
    }
  }
  
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
  }
  
  public var body: some Reducer<State, Action> {
    BindingReducer()
  }
}

public struct RideEventTypeView: View {
  let store: StoreOf<RideEventType>
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      SettingsRow {
        Button(
          action: {
            viewStore.send(
              .set(\.$isEnabled, !viewStore.state.isEnabled)
            )
          },
          label: {
            HStack(spacing: .grid(3)) {
              Text(viewStore.rideType.title)
                .padding(.vertical, .grid(2))
              Spacer()
              if viewStore.isEnabled {
                Image(systemName: "checkmark.circle.fill")
              } else {
                Image(systemName: "circle")
              }
            }
          }
        )
      }
      .accessibilityValue(viewStore.isEnabled ? Text(L10n.A11y.General.selected) : Text(""))
    }
  }
}
