import ApiClient
import BottomSheet
import ChatFeature
import ComposableArchitecture
import ComposableCoreLocation
import FileClient
import IDProvider
import L10n
import Logger
import MapFeature
import MapKit
import MastodonFeedFeature
import NextRideFeature
import SettingsFeature
import SharedDependencies
import SharedModels
import SocialFeature
import UIApplicationClient
import UserDefaultsClient

public struct AppFeature: Reducer {
  public init() {}
  
  @Dependency(\.fileClient) public var fileClient
  @Dependency(\.apiService) public var apiService
  @Dependency(\.uuid) public var uuid
  @Dependency(\.date) public var date
  @Dependency(\.continuousClock) public var clock
  @Dependency(\.userDefaultsClient) public var userDefaultsClient
  @Dependency(\.nextRideService) public var nextRideService
  @Dependency(\.idProvider) public var idProvider
  @Dependency(\.mainQueue) public var mainQueue
  @Dependency(\.locationManager) public var locationManager
  @Dependency(\.uiApplicationClient) public var uiApplicationClient
  @Dependency(\.setUserInterfaceStyle) public var setUserInterfaceStyle
  @Dependency(\.isNetworkAvailable) public var isNetworkAvailable
  
  // MARK: State

  public struct State: Equatable {
    public init(
      locationsAndChatMessages: TaskResult<[Rider]>? = nil,
      didResolveInitialLocation: Bool = false,
      mapFeatureState: MapFeature.State = .init(
        riders: [],
        userTrackingMode: UserTrackingFeature.State(userTrackingMode: .follow)
      ),
      socialState: SocialFeature.State = .init(),
      settingsState: SettingsFeature.State = .init(userSettings: .init()),
      nextRideState: NextRideFeature.State = .init(),
      requestTimer: RequestTimer.State = .init(),
      route: AppRoute? = nil,
      chatMessageBadgeCount: UInt = 0
    ) {
      self.riderLocations = locationsAndChatMessages
      self.didResolveInitialLocation = didResolveInitialLocation
      self.mapFeatureState = mapFeatureState
      self.socialState = socialState
      self.settingsState = settingsState
      self.nextRideState = nextRideState
      self.requestTimer = requestTimer
      self.route = route
      self.chatMessageBadgeCount = chatMessageBadgeCount
    }
    
    public var riderLocations: TaskResult<[Rider]>?
    public var didResolveInitialLocation = false
    public var isRequestingRiderLocations = false
    
    // Children states
    public var mapFeatureState = MapFeature.State(
      riders: [],
      userTrackingMode: UserTrackingFeature.State(userTrackingMode: .follow)
    )
    
    public var timerProgress: Double {
      let progress = Double(requestTimer.secondsElapsed) / 60
      return progress
    }
    public var sendLocation: Bool {
      requestTimer.secondsElapsed == 30
    }
    public var timerValue: String {
      let progress = 60 - requestTimer.secondsElapsed
      return String(progress)
    }
    public var ridersCount: String {
      let count = mapFeatureState.visibleRidersCount ?? 0
      return NumberFormatter.riderCountFormatter.string(from: .init(value: count)) ?? ""
    }
    
    public var socialState = SocialFeature.State()
    public var settingsState = SettingsFeature.State(userSettings: .init())
    public var nextRideState = NextRideFeature.State()
    public var requestTimer = RequestTimer.State()
      
    // Navigation
    public var route: AppRoute?
    public var isChatViewPresented: Bool { route == .chat }
    public var isRulesViewPresented: Bool { route == .rules }
    public var isSettingsViewPresented: Bool { route == .settings }
    
    public var chatMessageBadgeCount: UInt = 0

    @BindingState public var bottomSheetPosition: BottomSheetPosition = .hidden
    public var alert: AlertState<Action>?
    
    var hasOfflineError: Bool {
      switch riderLocations {
      case .failure(let error):
        guard let networkError = error as? NetworkRequestError else {
          return false
        }
        return networkError == .connectionLost
        
      default:
        return false
      }
    }
  }
  
  // MARK: Actions

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case appDelegate(AppDelegate.Action)
    case onAppear
    case onDisappear
    case fetchLocations
    case fetchLocationsResponse(TaskResult<[Rider]>)
    case postLocation
    case postLocationResponse(TaskResult<ApiResponse>)
    case fetchChatMessages
    case fetchChatMessagesResponse(TaskResult<[ChatMessage]>)
    case userSettingsLoaded(TaskResult<UserSettings>)
    case onRideSelectedFromBottomSheet(SharedModels.Ride)
    case setNavigation(tag: AppRoute.Tag?)
    case dismissSheetView
    case presentObservationModeAlert
    case setObservationMode(Bool)
    case dismissAlert
    
    case map(MapFeature.Action)
    case nextRide(NextRideFeature.Action)
    case requestTimer(RequestTimer.Action)
    case settings(SettingsFeature.Action)
    case social(SocialFeature.Action)
  }
  
  // MARK: Reducer
  public var body: some Reducer<State, Action> {
    BindingReducer()
    
    Scope(state: \.requestTimer, action: /AppFeature.Action.requestTimer) {
      RequestTimer()
    }
    
    Scope(state: \.mapFeatureState, action: /AppFeature.Action.map) {
      MapFeature()
    }
    
    Scope(state: \.nextRideState, action: /AppFeature.Action.nextRide) {
      NextRideFeature()
        .dependency(\.isNetworkAvailable, isNetworkAvailable)
    }
    
    Scope(state: \.settingsState, action: /AppFeature.Action.settings) {
      SettingsFeature()
    }
    
    Scope(state: \.socialState, action: /AppFeature.Action.social) {
      SocialFeature()
        .dependency(\.isNetworkAvailable, isNetworkAvailable)
    }
    
    /// Holds the logic for the AppFeature to update state and execute side effects
    self.core
  }
  
  var core: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .binding(\.$bottomSheetPosition):
        if state.bottomSheetPosition == .hidden {
          state.mapFeatureState.rideEvents = []
          state.mapFeatureState.eventCenter = nil
        } else {
          state.mapFeatureState.rideEvents = state.nextRideState.rideEvents
        }
        return .none
        
      case .appDelegate:
        return .none
        
      case .onRideSelectedFromBottomSheet(let ride):
        return .send(.map(.focusRideEvent(ride.coordinate)))
        
      case .onAppear:
        var effects: [Effect<Action>] = [
          .send(.map(.onAppear)),
          .send(.requestTimer(.startTimer)),
          .run { send in
            await send(.userSettingsLoaded(
              TaskResult {
                try await fileClient.loadUserSettings()
              }
            ))
          },
          .run { send in
            await withThrowingTaskGroup(of: Void.self) { group in
              group.addTask {
                await send(.fetchChatMessages)
              }
              group.addTask {
                await send(.fetchLocations)
              }
            }
          }
        ]
        if !userDefaultsClient.didShowObservationModePrompt {
          effects.append(
            .run { send in
              try? await mainQueue.sleep(for: .seconds(3))
              await send.callAsFunction(.presentObservationModeAlert)
            }
          )
        }
        
        return .merge(effects)
        
      case .onDisappear:
        return .none
        
      case .fetchLocations:
        state.isRequestingRiderLocations = true
        return .run { send in
          await send(
            .fetchLocationsResponse(
              TaskResult {
                try await apiService.getRiders()
              }
            )
          )
        }
        
      case .fetchChatMessages:
        return .run { send in
          await send(
            .fetchChatMessagesResponse(
              TaskResult {
                try await apiService.getChatMessages()
              }
            )
          )
        }
        
      case let .fetchChatMessagesResponse(.success(messages)):
        state.socialState.chatFeatureState.chatMessages = .results(messages)
        if !state.isChatViewPresented {
          let cachedMessages = messages.sorted(by: \.timestamp)
          
          let unreadMessagesCount = UInt(
            cachedMessages
              .filter { $0.timestamp > userDefaultsClient.chatReadTimeInterval }
              .count
          )
          state.chatMessageBadgeCount = unreadMessagesCount
        }
        return .none
        
      case let .fetchChatMessagesResponse(.failure(error)):
        state.socialState.chatFeatureState.chatMessages = .error(
          .init(
            title: L10n.error,
            body: "Failed to fetch chat messages",
            error: .init(error: error)
          )
        )
        logger.info("FetchLocation failed: \(error)")
        return .none
        
      case let .fetchLocationsResponse(.success(response)):
        state.isRequestingRiderLocations = false
        state.riderLocations = .success(response)
        state.mapFeatureState.riderLocations = response
        return .none
        
      case let .fetchLocationsResponse(.failure(error)):
        state.isRequestingRiderLocations = false
        logger.info("FetchLocation failed: \(error)")
        state.riderLocations = .failure(error)
        return .none
        
      case .postLocation:
        if state.settingsState.isObservationModeEnabled {
          return .none
        }
        
        let postBody = SendLocationPostBody(
          device: idProvider.id(),
          location: state.mapFeatureState.location
        )
        return .run { send in
          await send(
            .postLocationResponse(
              TaskResult {
                try await apiService.postRiderLocation(postBody)
              }
            )
          )
        }
        
      case .postLocationResponse(.success):
        return .none
        
      case .postLocationResponse(.failure(let error)):
        logger.debug("Failed to post location. Error: \(error.localizedDescription)")
        return .none

      case let .map(mapFeatureAction):
        switch mapFeatureAction {
        case .focusRideEvent, .focusNextRide:
          if state.bottomSheetPosition != .hidden {
            return .send(.set(\.$bottomSheetPosition, .relative(0.4)))
          } else {
            return .none
          }
          
        case .locationManager(.didUpdateLocations):
          state.nextRideState.userLocation = state.mapFeatureState.location?.coordinate
          return .none

        default:
          return .none
        }
        
      case let .nextRide(nextRideAction):
        switch nextRideAction {
        case let .setNextRide(ride):
          state.mapFeatureState.nextRide = ride
          return .run { send in
            await send.callAsFunction(.map(.setNextRideBannerVisible(true)))
            try? await mainQueue.sleep(for: .seconds(1))
            await send.callAsFunction(.map(.setNextRideBannerExpanded(true)))
            try? await mainQueue.sleep(for: .seconds(8))
            await send.callAsFunction(.map(.setNextRideBannerExpanded(false)))
          }
          
        default:
          return .none
        }
        
      case let .userSettingsLoaded(result):
        let userSettings = (try? result.value) ?? UserSettings()
        state.settingsState = .init(userSettings: userSettings)
        state.nextRideState.rideEventSettings = userSettings.rideEventSettings
        
        let style = state.settingsState.appearanceSettings.colorScheme.userInterfaceStyle
        let coordinate = state.mapFeatureState.location?.coordinate
        let isRideEventsEnabled = state.settingsState.rideEventSettings.isEnabled
        
        return .merge(
          .run { send in
            if isRideEventsEnabled, let coordinate {
              await send(.nextRide(.getNextRide(coordinate)))
            }
          },
          .run { _ in
            await setUserInterfaceStyle(style)
          }
        )

      case let .setNavigation(tag: tag):
        switch tag {
        case .chat:
          state.route = .chat
        case .rules:
          state.route = .rules
        case .settings:
          state.route = .settings
        case .none:
          state.route = .none
        }
        return .none

      case .dismissSheetView:
        state.route = .none
        return .send(.fetchLocations)
              
      case let .requestTimer(timerAction):
        switch timerAction {
        case .timerTicked:
          if state.requestTimer.secondsElapsed == 60 {
            state.requestTimer.secondsElapsed = 0
            
            return .run { [isChatPresented = state.isChatViewPresented, isPrentingSubView = state.route != nil] send in
              await withThrowingTaskGroup(of: Void.self) { group in
                if !isPrentingSubView {
                  group.addTask {
                    await send(.fetchLocations)
                  }
                }
                if isChatPresented {
                  group.addTask {
                    await send(.fetchChatMessages)
                  }
                }
              }
            }
          } else if state.sendLocation {
            return .send(.postLocation)
          } else {
            return .none
          }
          
        default:
          return .none
        }
        
      case .presentObservationModeAlert:
        state.alert = .viewingModeAlert
        return .none
        
      case let .setObservationMode(value):
        state.settingsState.isObservationModeEnabled = value
        return .run { _ in
          await userDefaultsClient.setDidShowObservationModePrompt(true)
        }
        
      case .dismissAlert:
        state.alert = nil
        return .none
        
      case let .social(socialAction):
        switch socialAction {
        case .chat(.onAppear):
          state.chatMessageBadgeCount = 0
          return .none

        default:
          return .none
        }
        
      case let .settings(settingsAction):
        switch settingsAction {
        case .rideevent:
          state.nextRideState.rideEventSettings = .init(state.settingsState.rideEventSettings)

          guard
            let coordinate = state.mapFeatureState.location?.coordinate,
            state.settingsState.rideEventSettings.isEnabled
          else {
            return .none
          }
          enum CancelID { case debounce }
          return .run { send in
            try await withTaskCancellation(id: CancelID.debounce, cancelInFlight: true) {
              try await self.clock.sleep(for: .seconds(2))
              await send(
                .nextRide(.getNextRide(coordinate))
              )
            }
          }
          
//          return .send(.nextRide(.getNextRide(coordinate)))
//            .debounce(id: RideEventRadiusSettingChange(), for: 2, scheduler: mainQueue)
        
        default:
          return .none
        }

      case .binding:
        return .none
      }
    }
  }
}

// MARK: - Helper

extension SharedModels.Location {
  /// Creates a Location object from an optional ComposableCoreLocation.Location
  init?(_ location: ComposableCoreLocation.Location?) {
    guard let location = location else {
      return nil
    }
    self = SharedModels.Location(
      coordinate: Coordinate(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude
      ),
      timestamp: location.timestamp.timeIntervalSince1970
    )
  }
}

extension SharedModels.Coordinate {
  /// Creates a Location object from an optional ComposableCoreLocation.Location
  init?(_ location: ComposableCoreLocation.Location?) {
    guard let location = location else {
      return nil
    }
    self = Coordinate(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude
    )
  }
}

public extension AlertState where Action == AppFeature.Action {
  static let viewingModeAlert = Self(
    title: .init(L10n.Settings.Observationmode.title),
    message: .init(L10n.AppCore.ViewingModeAlert.message),
    buttons: [
      .default(.init(L10n.AppCore.ViewingModeAlert.riding), action: .send(.setObservationMode(false))),
      .default(.init(L10n.AppCore.ViewingModeAlert.watching), action: .send(.setObservationMode(true)))
    ]
  )
}

extension NumberFormatter {
  static let riderCountFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = "."
    return formatter
  }()
}
