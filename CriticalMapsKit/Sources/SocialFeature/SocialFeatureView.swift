import ChatFeature
import ComposableArchitecture
import MastodonFeedFeature
import SwiftUI

/// A view that holds the chatfeature and twitterfeature and just offers a control to switch between the two.
public struct SocialView: View {
  @Environment(\.presentationMode) var presentationMode
  let store: StoreOf<SocialFeature>

  struct ViewState: Equatable {
    let selectedTab: SocialFeature.SocialControl
    init(state: SocialFeature.State) {
      self.selectedTab = state.socialControl
    }
  }
  
  public init(store: StoreOf<SocialFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      NavigationView {
        Group {
          switch viewStore.selectedTab {
          case .chat:
            ChatView(
              store: store.scope(
                state: \.chatFeatureState,
                action: SocialFeature.Action.chat
              )
            )
          case .toots:
            MastodonFeedView(
              store: store.scope(
                state: \.mastodonFeedState,
                action: SocialFeature.Action.toots
              )
            )
          }
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(
              action: { presentationMode.wrappedValue.dismiss() },
              label: {
                Image(systemName: "xmark")
                  .font(Font.system(size: 22, weight: .medium))
                  .foregroundColor(Color(.textPrimary))
              }
            )
          }

          ToolbarItem(placement: .principal) {
            Picker(
              "Social Segment",
              selection: viewStore.binding(
                get: \.selectedTab.rawValue,
                send: SocialFeature.Action.setSocialSegment
              )
            ) {
              Text(SocialFeature.SocialControl.chat.title).tag(0)
              Text(SocialFeature.SocialControl.toots.title).tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 180)
          }
        }
      }
    }
  }
}

// MARK: Preview

struct SocialView_Previews: PreviewProvider {
  static var previews: some View {
    SocialView(
      store: Store(
        initialState: SocialFeature.State(
          chatFeatureState: .init(),
          mastodonFeedState: .init()
        )
      ) {
        SocialFeature()._printChanges()
      }
    )
  }
}
