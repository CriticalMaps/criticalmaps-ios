import ApiClient
import ComposableArchitecture
import CryptoKit
import Foundation
import Helpers
import IDProvider
import L10n
import Logger
import SharedDependencies
import SharedModels
import UserDefaultsClient

public struct ChatFeature: Reducer {
  public init() {}
  
  @Dependency(\.date) public var date
  @Dependency(\.idProvider) public var idProvider
  @Dependency(\.apiService) public var apiService
  @Dependency(\.mainQueue) public var mainQueue
  @Dependency(\.uuid) public var uuid
  @Dependency(\.userDefaultsClient) public var userDefaultsClient
  @Dependency(\.isNetworkAvailable) public var isNetworkAvailable
  
  var md5Uuid: String {
    Insecure.MD5.hash(data: uuid().uuidString.data(using: .utf8)!)
      .map { String(format: "%02hhx", $0) }
      .joined()
  }

  // MARK: State
  
  public struct State: Equatable {
    public var chatMessages: ContentState<[ChatMessage]>
    public var chatInputState: ChatInput.State
    public var alert: AlertState<Action>?
    
    public init(
      chatMessages: ContentState<[ChatMessage]> = .loading([]),
      chatInputState: ChatInput.State = .init()
    ) {
      self.chatMessages = chatMessages
      self.chatInputState = chatInputState
    }
  }
  
  // MARK: Actions
  
  public enum Action: Equatable {
    case onAppear
    case chatInputResponse(TaskResult<ApiResponse>)
    case dismissAlert
    case fetchChatMessages
    case fetchChatMessagesResponse(TaskResult<[ChatMessage]>)
    
    case chatInput(ChatInput.Action)
  }
  
  // MARK: Reducer
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.chatInputState, action: /ChatFeature.Action.chatInput) {
      ChatInput()
    }
    
    // Reducer responsible for handling logic from the chat feature.
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .merge(
          .run { _ in
            await userDefaultsClient.setChatReadTimeInterval(date().timeIntervalSince1970)
          },
          .send(.fetchChatMessages)
        )
        
      case .fetchChatMessages:
        state.chatMessages = .loading(state.chatMessages.elements ?? [])
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
        state.chatMessages = .results(messages)
        return .none
        
      case let .fetchChatMessagesResponse(.failure(error)):
        state.chatMessages = .error(
          .init(
            title: L10n.error,
            body: "Failed to fetch chat messages",
            error: .init(error: error)
          )
        )
        logger.info("FetchLocation failed: \(error)")
        return .none
        
      case .dismissAlert:
        state.alert = nil
        return .none
        
      case .chatInputResponse(.success):
        state.chatInputState.isSending = false
        state.chatInputState.message.removeAll()
        return .send(.fetchChatMessages)
        
      case let .chatInputResponse(.failure(error)):
        state.chatInputState.isSending = false
        
        state.alert = AlertState(
          title: .init(L10n.error),
          message: .init("Failed to send chat message")
        )
        
        logger.debug("ChatInput Action failed with error: \(error.localizedDescription)")
        return .none
        
      case let .chatInput(chatInputAction):
        switch chatInputAction {
        case .onCommit:
          let message = ChatMessagePost(
            text: state.chatInputState.message,
            device: idProvider.id(),
            identifier: md5Uuid
          )
          
          state.chatInputState.isSending = true
          
          return .run { send in
            await send(
              .chatInputResponse(
                TaskResult {
                  try await apiService.postChatMessage(message)
                }
              )
            )
          }
          
        default:
          return .none
        }
      }
    }
  }
}
