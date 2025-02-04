import ComposableArchitecture
import Foundation
import L10n
import MastodonKit
import SharedModels
import Styleguide
import SwiftUI

public struct TootsListView: View {
  @State private var store: StoreOf<TootFeedFeature>

  public init(store: StoreOf<TootFeedFeature>) {
    self.store = store
  }

  public var body: some View {
    if store.isLoading, !store.isRefreshing {
      loadingView()
    } else {
      contentView()
        .refreshable {
          await store.send(.refresh).finish()
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
    if store.toots.isEmpty {
      EmptyStateView(
        emptyState: .mastodon,
        buttonAction: { store.send(.fetchData) },
        buttonText: L10n.EmptyState.reload
      )
    } else if let error = store.error {
      ErrorStateView(
        errorState: error,
        buttonAction: { store.send(.fetchData) },
        buttonText: "Reload"
      )
    } else {
      ZStack {
        Color(.backgroundPrimary)
          .ignoresSafeArea()

        List {
          ForEachStore(
            store.scope(
              state: \.toots,
              action: \.toot
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

#Preview {
  Group {
    TootsListView(
      store: StoreOf<TootFeedFeature>(
        initialState: .init(toots: IdentifiedArray(uniqueElements: [TootFeature.State].placeHolder)),
        reducer: { TootFeedFeature()._printChanges() }
      )
    )

    TootsListView(store: .placeholder)
      .redacted(reason: .placeholder)
  }
}

// MARK: - Helper

public extension EmptyState {
  static let mastodon = Self(
    icon: Asset.toot.image,
    text: L10n.Twitter.noData,
    message: NSAttributedString(string: L10n.Twitter.Empty.message)
  )
}
