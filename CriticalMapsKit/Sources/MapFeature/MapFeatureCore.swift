import ComposableCoreLocation
import Foundation
import L10n
import MapKit
import SharedModels

@propertyWrapper
public struct ShouldAnimateTrackingModeOverTime {
  private var values = [false, true]
  
  public init() {}
  
  public var wrappedValue: Bool {
    mutating get { getValue() }
    set {}
  }
  
  private mutating func getValue() -> Bool {
    guard values.count != 1 else {
      return values[0]
    }
    return values.removeFirst()
  }
}

public struct MapFeature: ReducerProtocol {
  public init() {}
  
  @Dependency(\.mainQueue) public var mainQueue
  @Dependency(\.locationManager) public var locationManager
  
  // MARK: State
  
  public struct State: Equatable {
    public var alert: AlertState<Action>?
    public var isRequestingCurrentLocation: Bool
    public var location: ComposableCoreLocation.Location?
    public var riderLocations: [Rider]
    public var nextRide: Ride?
    
    public var rideEvents: [Ride] = []
    
    @BindableState public var eventCenter: CoordinateRegion?
    @BindableState public var userTrackingMode: UserTrackingFeature.State
    @BindableState public var centerRegion: CoordinateRegion?
    @BindableState public var presentShareSheet = false
    
    @ShouldAnimateTrackingModeOverTime
    public var shouldAnimateTrackingMode: Bool
    public var isNextRideBannerVisible = false
    public var isNextRideBannerExpanded = false
    
    public init(
      alert: AlertState<Action>? = nil,
      isRequestingCurrentLocation: Bool = false,
      location: ComposableCoreLocation.Location? = nil,
      riders: [Rider],
      userTrackingMode: UserTrackingFeature.State,
      nextRide: Ride? = nil,
      centerRegion: CoordinateRegion? = nil
    ) {
      self.alert = alert
      self.isRequestingCurrentLocation = isRequestingCurrentLocation
      self.location = location
      self.riderLocations = riders
      self.userTrackingMode = userTrackingMode
      self.nextRide = nextRide
      self.centerRegion = centerRegion
    }
    
    public static func == (lhs: MapFeature.State, rhs: MapFeature.State) -> Bool {
      lhs.alert == rhs.alert
      && lhs.isNextRideBannerExpanded == rhs.isNextRideBannerExpanded
      && lhs.isNextRideBannerVisible == rhs.isNextRideBannerVisible
      && lhs.presentShareSheet == rhs.presentShareSheet
      && lhs.isRequestingCurrentLocation == rhs.isRequestingCurrentLocation
      && lhs.location == rhs.location
      && lhs.riderLocations == rhs.riderLocations
      && lhs.userTrackingMode == rhs.userTrackingMode
      && lhs.nextRide == rhs.nextRide
      && lhs.centerRegion == rhs.centerRegion
      && lhs.isNextRideBannerVisible == rhs.isNextRideBannerVisible
      && lhs.isNextRideBannerExpanded == rhs.isNextRideBannerExpanded
    }
  }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case onAppear
    case locationRequested
    case nextTrackingMode
    case updateUserTrackingMode(UserTrackingFeature.State)
    case updateCenterRegion(CoordinateRegion?)
    case focusNextRide(Coordinate?)
    case focusRideEvent(Coordinate?)
    case resetCenterRegion
    case resetRideEventCenter

    case showShareSheet(Bool)
    case routeToEvent
    
    case setNextRideBannerExpanded(Bool)
    case setNextRideBannerVisible(Bool)
    
    case locationManager(LocationManager.Action)
    case userTracking(UserTrackingFeature.Action)
  }

  /// Used to identify locatioManager effects.
  private struct LocationManagerId: Hashable {}
  
  public var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    
    Scope(state: \.userTrackingMode, action: /MapFeature.Action.userTracking) {
      UserTrackingFeature()
    }
    
    Scope(state: \.self, action: /MapFeature.Action.locationManager) {
      Reduce<State, LocationManager.Action> { state, action in
        switch action {
        case .didChangeAuthorization(.authorizedAlways),
             .didChangeAuthorization(.authorizedWhenInUse):
          if state.isRequestingCurrentLocation {
            return locationManager
              .requestLocation()
              .fireAndForget()
          }
          return .none
          
        case .didChangeAuthorization(.denied):
          if state.isRequestingCurrentLocation {
            state.alert = AlertState(
              title: TextState("Location makes this app better. Please consider giving us access.")
            )
            state.isRequestingCurrentLocation = false
          }
          return .none
          
        case let .didUpdateLocations(locations):
          state.isRequestingCurrentLocation = false
          guard let location = locations.first else { return .none }
          state.location = location
          return .none
          
        default:
          return .none
        }
      }
    }
    
    Reduce<State, Action> { state, action in
      switch action {
      case .binding:
        return .none
        
      case let .setNextRideBannerVisible(value):
        state.isNextRideBannerVisible = value
        return .none
        
      case let .setNextRideBannerExpanded(value):
        state.isNextRideBannerExpanded = value
        return .none
      
      case .onAppear:
        return .merge(
          locationManager
            .delegate()
            .map(Action.locationManager),
          
          locationManager
            .setup()
            .fireAndForget(),
          
          Effect(value: Action.locationRequested)
        )
        
      case .locationRequested:
        guard locationManager.locationServicesEnabled() else {
          state.alert = .servicesOff
          return .none
        }
        switch locationManager.authorizationStatus() {
        case .notDetermined:
          state.isRequestingCurrentLocation = true
          
          return locationManager
            .requestAlwaysAuthorization()
            .fireAndForget()
          
        case .restricted:
          state.alert = .goToSettingsAlert
          return .none
          
        case .denied:
          state.alert = .goToSettingsAlert
          return .none
          
        case .authorizedAlways, .authorizedWhenInUse:
          return locationManager
            .startUpdatingLocation()
            .fireAndForget()
          
        @unknown default:
          return .none
        }
        
      case .nextTrackingMode:
        switch state.userTrackingMode.mode {
        case .follow:
          return Effect(value: .updateUserTrackingMode(.init(userTrackingMode: .followWithHeading)))
        case .followWithHeading:
          return Effect(value: .updateUserTrackingMode(.init(userTrackingMode: .none)))
        case .none:
          return Effect(value: .updateUserTrackingMode(.init(userTrackingMode: .follow)))
        @unknown default:
          fatalError()
        }
        
      case let .updateUserTrackingMode(mode):
        state.shouldAnimateTrackingMode = mode.mode != state.userTrackingMode.mode
        state.userTrackingMode.mode = mode.mode
        return .none

      case let .focusNextRide(coordinate):
        guard let nextRideCoordinate = coordinate else {
          return .none
        }
        state.centerRegion = CoordinateRegion(center: nextRideCoordinate.asCLLocationCoordinate)
        
        return Effect.run { send in
          try await mainQueue.sleep(for: .seconds(1))
          await send.send(.resetCenterRegion)
        }

      case let .focusRideEvent(coordinate):
        guard let coordinate = coordinate else {
          return .none
        }

        state.eventCenter = CoordinateRegion(center: coordinate.asCLLocationCoordinate)
        
        return Effect.run { send in
          try await mainQueue.sleep(for: .seconds(1))
          await send.send(.resetRideEventCenter)
        }

      case .resetRideEventCenter:
        state.eventCenter = nil
        return .none

      case .resetCenterRegion:
        state.centerRegion = nil
        return .none
        
      case let .showShareSheet(value):
        state.presentShareSheet = value
        return .none
        
      case .routeToEvent:
        state.nextRide?.openInMaps()
        return .none
        
      case .locationManager, .userTracking, .updateCenterRegion:
        return .none
      }
    }
  }
}

// MARK: - Helper

extension LocationManager {
  /// Configures the LocationManager
  func setup() -> Effect<Never, Never> {
    set(
      .init(
        activityType: .otherNavigation,
        allowsBackgroundLocationUpdates: true,
        desiredAccuracy: kCLLocationAccuracyBestForNavigation,
        distanceFilter: nil,
        headingFilter: nil,
        pausesLocationUpdatesAutomatically: false,
        showsBackgroundLocationIndicator: true
      )
    )
  }
}

public extension AlertState where Action == MapFeature.Action {
  static let goToSettingsAlert = Self(
    title: TextState(L10n.Location.Alert.provideAccessToLocationService),
    primaryButton: .default(TextState(L10n.Settings.title)),
    secondaryButton: .default(TextState(L10n.ok))
  )
  
  static let provideAuth = Self(title: TextState(L10n.Location.Alert.provideAuth))
  static let servicesOff = Self(title: TextState(L10n.Location.Alert.serviceIsOff))
  static let provideAccessToLocationService = Self(
    title: TextState(L10n.Location.Alert.provideAccessToLocationService)
  )
}

// MARK: - Dependencies

enum LocationManagerKey: DependencyKey {
  static let liveValue = LocationManager.live
  static let testValue = LocationManager.failing
}

public extension DependencyValues {
  var locationManager: LocationManager {
    get { self[LocationManagerKey.self] }
    set { self[LocationManagerKey.self] = newValue }
  }
}
