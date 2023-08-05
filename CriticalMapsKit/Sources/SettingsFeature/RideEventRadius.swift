import ComposableArchitecture
import Foundation
import L10n
import SharedModels
import SwiftUI

public struct RideEventRadius: Reducer {
  public init() {}
  
  public struct State: Equatable, Identifiable, Sendable, Codable {
    public let id: UUID
    public let eventDistance: EventDistance
    @BindingState public var isSelected = false
    
    public init(id: UUID, eventDistance: EventDistance, isSelected: Bool) {
      self.id = id
      self.eventDistance = eventDistance
      self.isSelected = isSelected
    }
  }
  
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
  }
  
  public var body: some Reducer<State, Action> {
    BindingReducer()
  }
}

public struct RideEventRadiusView: View {
  let store: StoreOf<RideEventRadius>
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      SettingsRow {
        Button(
          action: { viewStore.send(.set(\.$isSelected, true)) },
          label: {
            HStack(spacing: .grid(3)) {
              Text(String(viewStore.eventDistance.displayValue))
                .accessibility(label: Text(viewStore.eventDistance.displayValue))
                .padding(.vertical, .grid(2))
              Spacer()
              if viewStore.isSelected {
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
