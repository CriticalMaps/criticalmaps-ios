import ComposableArchitecture
import Foundation
import Helpers
import MastodonKit
import SharedModels
import Styleguide
import SwiftUI
import UIApplicationClient

public struct TootFeature: Reducer {
  public init() {}
  
  @Dependency(\.uiApplicationClient) public var uiApplicationClient
  
  public typealias State = MastodonKit.Status
  
  public enum Action {
    case openTweet
    case openUser
  }
  
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .openTweet:
      guard let tootUrl = URL(string: state.uri) else {
        return .none
      }
      return .run { _ in
        _ = await uiApplicationClient.open(tootUrl, [:])
      }
      
    case .openUser:
      guard let accountUrl = URL(string: state.account.url) else {
        return .none
      }
      return .run { _ in
        _ = await uiApplicationClient.open(accountUrl, [:])
      }
    }
  }
}

/// A view that renders a tweet
public struct TootView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize
  @Environment(\.colorScheme) private var colorScheme
  
  let store: StoreOf<TootFeature>
  @ObservedObject var viewStore: ViewStoreOf<TootFeature>
  
  public init(store: StoreOf<TootFeature>) {
    self.store = store
    self.viewStore = ViewStore(store, observe: { $0 })
  }
  
  public var body: some View {
    ZStack {
      HStack(alignment: .top, spacing: .grid(4)) {
        AsyncImage(
          url: URL(string: viewStore.state.account.avatar),
          transaction: Transaction(animation: .easeInOut)
        ) { phase in
          switch phase {
          case .empty:
            Color(.textSilent).opacity(0.6)
          case let .success(image):
            image
              .resizable()
              .transition(.opacity)
          case .failure:
            Color(.textSilent).opacity(0.6)
          @unknown default:
            EmptyView()
          }
        }
        .frame(width: 44, height: 44)
        .background(Color.gray)
        .clipShape(Circle())
        
        VStack(alignment: .leading, spacing: .grid(2)) {
          tweetheader()
            .contentShape(Rectangle())
            .onTapGesture {
              viewStore.send(.openUser)
            }
          
          if let content = viewStore.content.convertHtmlToAttributedStringWithCSS(
            csscolor: colorScheme == .light ? "black" : "white",
            linkColor: colorScheme == .light ? "#1717E5" : "#FFD633"
          ) {
            Text(content)
              .id(dynamicTypeSize.hashValue)
              .contentShape(Rectangle())
              .onTapGesture {
                viewStore.send(.openTweet)
              }
              .accessibilityAction(
                action: { viewStore.send(.openTweet) },
                label: { Text("Open tweet")
                    .accessibilityHint("Opens the tweet in the twitter app if it is installed")
                }
              )
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
    .padding(.vertical, .grid(2))
  }
  
  @ViewBuilder
  func tweetheader() -> some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading) {
          if !viewStore.account.displayName.isEmpty {
            displayName
          }
          accountName
          tweetPostDatetime
        }
      } else {
        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            if !viewStore.account.displayName.isEmpty {
              displayName
            }
            accountName
          }
          Spacer()
          tweetPostDatetime
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityRepresentation(representation: {
      HStack {
        if !viewStore.account.displayName.isEmpty {
          displayName
        }
        displayName
        Text("posted")
        tweetPostDatetime
      }
    })
  }

  var displayName: some View {
    Text(viewStore.account.displayName)
      .lineLimit(1)
      .font(.titleTwo)
      .foregroundColor(Color(.textPrimary))
  }

  var accountName: some View {
    Text(viewStore.account.acct)
      .lineLimit(1)
      .font(.bodyTwo)
      .foregroundColor(Color(.textSilent))
      .accessibilityHidden(true)
  }

  var tweetPostDatetime: some View {
    let (text, a11yValue) = viewStore.state.formattedCreationDate()
    return Text(text ?? "")
      .font(.meta)
      .foregroundColor(Color(.textPrimary))
      .accessibilityLabel(a11yValue ?? "")
  }
}

// MARK: Preview

struct TweetView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      TootView(store: Store(initialState: [Status].placeHolder[0]) {
        TootFeature()
      })
      
      TootView(store: Store(initialState: [Status].placeHolder[0]) {
        TootFeature()
      })
      .redacted(reason: .placeholder)
    }
  }
}

public extension MastodonKit.Status {
  
  func formattedCreationDate(
    currentDate: () -> Date = Date.init,
    calendar: () -> Calendar = { .current }
  ) -> (String?, String?) {
    let components = calendar().dateComponents(
      [.hour, .day, .month],
      from: createdAt,
      to: currentDate()
    )
    
    let a11yValue = RelativeDateTimeFormatter.tweetDateFormatter.localizedString(for: createdAt, relativeTo: currentDate())
    
    if let days = components.day, days == 0, let months = components.month, months == 0 {
      let diffComponents = calendar().dateComponents([.hour, .minute], from: createdAt, to: currentDate())
      
      let value = DateComponentsFormatter.tweetDateFormatter()
        .string(from: diffComponents.dateComponentFromBiggestComponent)
      return (value, a11yValue)
    } else {
      let value = createdAt.formatted(Date.FormatStyle.dateWithoutYear)
      return (value, a11yValue)
    }
  }
}

extension DateComponents {
  var dateComponentFromBiggestComponent: DateComponents {
    if let day = day, day != 0 {
      return DateComponents(calendar: calendar, day: day)
    } else if let hour = hour, hour != 0 {
      return DateComponents(calendar: calendar, hour: hour)
    } else {
      return DateComponents(calendar: calendar, minute: minute)
    }
  }
}

extension RelativeDateTimeFormatter {
  static let tweetDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter
  }()
}

extension String {
  private var convertHtmlToNSAttributedString: NSAttributedString? {
    guard let data = data(using: .utf8) else {
      return nil
    }
    do {
      return try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.unicode.rawValue
        ],
        documentAttributes: nil
      )
    } catch {
      debugPrint(error.localizedDescription)
      return nil
    }
  }
  
  public func convertHtmlToAttributedStringWithCSS(
    font: UIFont? = UIFont(name: "Helvetica", size: UIFont.preferredFont(forTextStyle: .body).pointSize),
    csscolor: String,
    linkColor: String,
    lineheight: Int = 5,
    csstextalign: String = "left"
  ) -> NSAttributedString? {
    guard let font = font else {
      return convertHtmlToNSAttributedString
    }
    let modifiedString = "<style>body{font-family: '\(font.fontName)'; font-size:\(font.pointSize)px; color: \(csscolor); line-height: \(lineheight)px; text-align: \(csstextalign);} a{color: \(linkColor)}</style>\(self)"
    guard let data = modifiedString.data(using: .unicode) else {
      return nil
    }
    do {
      return try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.unicode.rawValue
        ],
        documentAttributes: nil
      )
    } catch {
      debugPrint(error.localizedDescription)
      return nil
    }
  }
}
