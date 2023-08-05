import ComposableArchitecture
import L10n
import MapKit

public struct UserTrackingFeature: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(userTrackingMode: MKUserTrackingMode) {
      mode = userTrackingMode
    }

    public var mode: MKUserTrackingMode
  }

  public enum Action: Equatable {
    case nextTrackingMode
  }

  /// Reducer handling tracking mode button state changes
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .nextTrackingMode:
      switch state.mode {
      case .follow:
        state.mode = .followWithHeading
      case .followWithHeading:
        state.mode = .none
      case .none:
        state.mode = .follow
      @unknown default:
        fatalError()
      }
      return .none
    }
  }
}

public extension MKUserTrackingMode {
  var accessiblityLabel: String {
    switch self {
    case .follow:
      return L10n.A11y.Usertrackingbutton.follow
    case .followWithHeading:
      return L10n.A11y.Usertrackingbutton.followWithHeading
    case .none:
      return L10n.A11y.Usertrackingbutton.dontFollow
    @unknown default:
      return ""
    }
  }
}
