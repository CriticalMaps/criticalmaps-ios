import ComposableArchitecture
import Foundation
import L10n
import MastodonKit
import SharedModels
import Styleguide
import SwiftUI

public struct TootsListView: View {
  let store: StoreOf<TootFeedFeature>
  @ObservedObject var viewStore: ViewStoreOf<TootFeedFeature>

  public init(store: StoreOf<TootFeedFeature>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  public var body: some View {
    if viewStore.isLoading, !viewStore.isRefreshing {
      loadingView()
    } else {
      contentView()
      .refreshable {
        Task {
          await viewStore.send(.refresh, while: \.isLoading)
        }
      }
    }
  }
  
  @ViewBuilder
  func loadingView() -> some View {
    VStack {
      Spacer()
      ProgressView {
        Text("Loading")
          .foregroundColor(Color(.textPrimary))
          .font(.bodyOne)
      }
      Spacer()
    }
  }
  
  @ViewBuilder
  func contentView() -> some View {
    if viewStore.toots.isEmpty {
      EmptyStateView(
        emptyState: .twitter,
        buttonAction: { viewStore.send(.fetchData) },
        buttonText: L10n.EmptyState.reload
      )
    } else if let error = viewStore.error {
      ErrorStateView(
        errorState: error,
        buttonAction: { viewStore.send(.fetchData) },
        buttonText: "Reload"
      )
    } else {
      ZStack {
        Color(.backgroundPrimary)
          .ignoresSafeArea()
        
        List {
          ForEachStore(
            self.store.scope(
              state: \.toots,
              action: TootFeedFeature.Action.toot
            )
          ) {
            TootView(store: $0)
          }
        }
        .listRowBackground(Color(.backgroundPrimary))
        .listStyle(PlainListStyle())
      }
    }
  }
}

// MARK: Preview

struct TootsListView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
//      TootsListView(
//        store: Store(
//          initialState: TootFeedFeature.State(
//            toots: IdentifiedArray(uniqueElements: [Status].placeHolder)
//          )
//        ) {
//          TootFeedFeature()
//        }
//      )

//      TootsListView(store: .placeholder)
//        .redacted(reason: .placeholder)
    }
  }
}

public extension EmptyState {
  static let twitter = Self(
    icon: Asset.twitterEmpty.image,
    text: L10n.Twitter.noData,
    message: NSAttributedString(string: L10n.Twitter.Empty.message)
  )
}
