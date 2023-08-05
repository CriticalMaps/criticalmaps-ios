import ApiClient
import ChatFeature
import ComposableArchitecture
import Foundation
import IDProvider
import L10n
import MastodonFeedFeature
import UIApplicationClient
import UserDefaultsClient

public struct SocialFeature: Reducer {
  public init() {}
  
  @Dependency(\.isNetworkAvailable) public var isNetworkAvailable
  
  // MARK: State
  
  public struct State: Equatable {
    public var chatFeatureState: ChatFeature.State
    public var mastodonFeedState: TootFeedFeature.State
    public var socialControl: SocialControl
        
    public init(
      socialControl: SocialControl = .chat,
      chatFeatureState: ChatFeature.State = .init(),
      mastodonFeedState: TootFeedFeature.State = .init()
    ) {
      self.socialControl = socialControl
      self.chatFeatureState = chatFeatureState
      self.mastodonFeedState = mastodonFeedState
    }
  }
  
  public enum SocialControl: Int, Equatable {
    case chat, toots
    
    var title: String {
      switch self {
      case .chat:
        return L10n.Chat.title
      case .toots:
        return "Mastodon"
      }
    }
  }
  
  // MARK: Actions
  
  public enum Action: Equatable {
    case setSocialSegment(Int)
    
    case chat(ChatFeature.Action)
    case toots(TootFeedFeature.Action)
  }
    
  // MARK: Reducer
  
  public var body: some Reducer<State, Action> {
    Scope(state: \.chatFeatureState, action: /SocialFeature.Action.chat) {
      ChatFeature()
        .dependency(\.isNetworkAvailable, isNetworkAvailable)
    }
    
    Scope(state: \.mastodonFeedState, action: /SocialFeature.Action.toots) {
      TootFeedFeature()
    }
    
    Reduce<State, Action> { state, action in
      switch action {
      case let .setSocialSegment(segment):
        state.socialControl = .init(rawValue: segment)!
        return .none
      
      case .chat, .toots:
        return .none
      }
    }
  }
}
