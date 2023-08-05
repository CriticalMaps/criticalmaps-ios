import ComposableArchitecture
import Helpers
import L10n
import SharedModels
import Styleguide
import SwiftUI

/// A list to show messages from the chat and send a message
public struct ChatView: View {
  public struct ViewState: Equatable {
    public let messages: [ChatMessage]
    
    public init(_ state: ChatFeature.State) {
      messages = state.chatMessages.elements?
        .sorted { $0.timestamp > $1.timestamp } ?? []
    }
  }
  
  let store: StoreOf<ChatFeature>
  @ObservedObject var viewStore: ViewStore<ViewState, ChatFeature.Action>
  
  public init(store: StoreOf<ChatFeature>) {
    self.store = store
    viewStore = ViewStore(
      store.scope(
        state: ViewState.init,
        action: { $0 }
      ),
      observe: { $0 }
    )
  }
  
  public var body: some View {
    VStack {
      ZStack(alignment: .bottom) {
        Color(.backgroundPrimary)
          .ignoresSafeArea()
          .accessibilityHidden(true)
        
        if viewStore.messages.isEmpty {
          emptyState
            .accessibilitySortPriority(-1)
        } else {
          List(viewStore.messages) { chat in
            ChatMessageView(chat)
              .padding(.horizontal, .grid(4))
              .padding(.vertical, .grid(2))
              .animation(nil, value: viewStore.messages)
          }
          .listRowBackground(Color(.backgroundPrimary))
          .listStyle(PlainListStyle())
          .accessibleAnimation(.easeOut, value: viewStore.messages)
        }
      }
      
      chatInput
    }
//    .alert(store: self.store.scope(state: \.alert, action: { _ in .dismissAlert }))
    .onAppear { viewStore.send(.onAppear) }
    .navigationBarTitleDisplayMode(.inline)
    .ignoresSafeArea(.container, edges: .bottom)
  }
  
  private var chatInput: some View {
    ZStack(alignment: .top) {
      BasicInputView(
        store: self.store.scope(
          state: \.chatInputState,
          action: ChatFeature.Action.chatInput
        ),
        placeholder: L10n.Chat.placeholder
      )
      .padding(.horizontal, .grid(3))
      .padding(.top, .grid(2))
      .padding(.bottom, .grid(7))
      
      Color(.border)
        .frame(height: 2)
    }
    .background(Color(.backgroundSecondary))
  }
  
  private var emptyState: some View {
    EmptyStateView(
      emptyState: .init(
        icon: Asset.chatEmpty.image,
        text: L10n.Chat.emptyMessageTitle,
        message: .init(
          string: L10n.Chat.noChatActivity
        )
      )
    )
  }
}

// MARK: Preview

struct ChatView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView(
      store: Store(initialState: .init()) {
        ChatFeature()
      }
    )
  }
}
