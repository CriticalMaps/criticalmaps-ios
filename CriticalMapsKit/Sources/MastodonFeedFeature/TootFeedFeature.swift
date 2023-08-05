import ComposableArchitecture
import Foundation
import Helpers
import L10n
import Logger
import MastodonKit
import SharedDependencies
import SharedModels
import Styleguide
import SwiftUI
import UIApplicationClient

public struct TootFeedFeature: Reducer {
  public init() {}
  
  @Dependency(\.mainQueue) public var mainQueue
  @Dependency(\.tootService) public var tootService
  @Dependency(\.uiApplicationClient) public var uiApplicationClient

  // MARK: State

  public struct State: Equatable {
    public var toots: IdentifiedArrayOf<MastodonKit.Status>
    public var isLoading = false
    public var isRefreshing = false
    public var error: ErrorState?
        
    public init(
      toots: IdentifiedArrayOf<Status> = []
    ) {
      self.toots = toots
    }
  }
  
  // MARK: Actions
  
  public enum Action: Equatable {
    case onAppear
    case refresh
    case fetchData
    case fetchDataResponse(TaskResult<[Status]>)
    case toot(id: TootFeature.State.ID, action: TootFeature.Action)
  }
  
  
  // MARK: Reducer
  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.fetchData)
        
      case .refresh:
        state.isRefreshing = true
        return .send(.fetchData)
        
      case .fetchData:
        state.isLoading = true
        return .run { send in
          await send(.fetchDataResponse(TaskResult { try await tootService.getToots() }))
        }
        
      case let .fetchDataResponse(.success(toots)):
        state.isLoading = false
        state.isRefreshing = false
        
        if toots.isEmpty {
          state.toots = .init(uniqueElements: [])
          return .none
        }
        
        state.toots = IdentifiedArray(uniqueElements: toots)
        return .none
      case let .fetchDataResponse(.failure(error)):
        logger.debug("Failed to fetch tweets with error: \(error.localizedDescription)")
        state.isRefreshing = false
        state.isLoading = false
        state.error = .init(
          title: L10n.ErrorState.title,
          body: L10n.ErrorState.message,
          error: .init(error: error)
        )
        return .none
        
      case .toot:
        return .none
      }
    }
    .forEach(\.toots, action: /TootFeedFeature.Action.toot) {
      TootFeature()
    }
  }
}

extension MastodonKit.Status: Identifiable {
  public static func == (lhs: MastodonKit.Status, rhs: MastodonKit.Status) -> Bool {
    lhs.id == rhs.id
  }
}
