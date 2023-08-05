import ComposableArchitecture
import Foundation
import MastodonKit
import SharedModels
import Styleguide
import SwiftUI

public struct MastodonFeedView: View {
  public struct MastodonFeedViewState: Equatable {
    public let displayPlaceholder: Bool

    public init(_ state: TootFeedFeature.State) {
      if state.isLoading && !state.isRefreshing {
        displayPlaceholder = true
      } else {
        displayPlaceholder = false
      }
    }
  }

  let store: StoreOf<TootFeedFeature>
  @ObservedObject var viewStore: ViewStore<MastodonFeedViewState, TootFeedFeature.Action>

  public init(store: StoreOf<TootFeedFeature>) {
    self.store = store
    viewStore = ViewStore(
      store.scope(
        state: MastodonFeedViewState.init,
        action: { $0 }
      ),
      observe: { $0 }
    )
  }

  public var body: some View {
    TootsListView(store: self.store)
      .navigationBarTitleDisplayMode(.inline)
      .onAppear { viewStore.send(.onAppear) }
  }
}

// MARK: Preview

struct MastodonFeedView_Previews: PreviewProvider {
  static var previews: some View {
    MastodonFeedView(
      store: Store(initialState: .init()) {
        TootFeedFeature()._printChanges()
      }
    )
  }
}

public extension Array where Element == MastodonKit.Status {
  static let placeHolder: Self = [0, 1, 2, 3, 4].map {
    Status(
      id: String($0),
      uri: "",
      url: nil,
      account: .init(
        id: String($0),
        username: "@criticalmaps",
        acct: "@criticalmaps@mastodon.social",
        displayName: "Critical Maps",
        note: "",
        url: "",
        avatar: "",
        avatarStatic: "",
        header: "",
        headerStatic: "",
        locked: false,
        createdAt: .init(timeIntervalSince1970: TimeInterval(1635521516)),
        followersCount: 11,
        followingCount: 8,
        statusesCount: 0
      ),
      inReplyToID: nil,
      inReplyToAccountID: nil,
      content: String("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed invidunt ut labore et dolore".dropLast($0)),
      createdAt: .init(timeIntervalSince1970: TimeInterval(1635521516)),
      emojis: [],
      reblogsCount: 0,
      favouritesCount: 0,
      reblogged: nil,
      favourited: nil,
      bookmarked: nil,
      sensitive: nil,
      spoilerText: "",
      visibility: .public,
      mediaAttachments: [],
      mentions: [],
      tags: [],
      application: nil,
      language: nil,
      reblog: nil,
      pinned: nil,
      card: nil,
      repliesCount: 0
    )
  }
}

extension Store where State == TootFeedFeature.State, Action == TootFeedFeature.Action {
//  static let placeholder = StoreOf<TootFeedFeature>(
//    initialState: .init(
//      toots: IdentifiedArray(
//        uniqueElements: [MastodonKit.Status].placeHolder
//      )
//    )
//  )
}
