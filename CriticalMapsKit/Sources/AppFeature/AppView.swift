import BottomSheet
import ComposableArchitecture
import L10n
import MapFeature
import SharedDependencies
import SharedModels
import Styleguide
import SwiftUI

/// The apps main view
public struct AppView: View {
  @State var showsInfoExpanded = false
  
  let store: StoreOf<AppFeature>
  @ObservedObject var viewStore: ViewStoreOf<AppFeature>

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @State private var showOfflineBanner = false

  public init(store: StoreOf<AppFeature>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  private var contextMenuTitle: String {
    if viewStore.bottomSheetPosition == .hidden {
      return L10n.Map.NextRideEvents.showAll
    } else {
      return L10n.Map.NextRideEvents.hideAll
    }
  }
  
  public var body: some View {
    ZStack(alignment: .topLeading) {
      MapFeatureView(
        store: store.scope(
          state: \.mapFeatureState,
          action: AppFeature.Action.map
        )
      )
      .edgesIgnoringSafeArea(.vertical)

      HStack {
        VStack(alignment: .leading) {
          if viewStore.mapFeatureState.isNextRideBannerVisible, viewStore.settingsState.rideEventSettings.isEnabled {
            nextRideBanner()
              .contextMenu {
                Button(
                  action: { viewStore.send(.set(\.$bottomSheetPosition, .relative(0.4))) },
                  label: { Label(contextMenuTitle, systemImage: "list.bullet") }
                )
              }
          }
          
          if viewStore.settingsState.infoViewEnabled {
            ZStack(alignment: .center) {
              Blur()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .frame(width: showsInfoExpanded ? 120 : 50, height: showsInfoExpanded ? 230 : 50)
                .accessibleAnimation(.cmSpring.speed(1.5), value: showsInfoExpanded)
              
              infoContent()
            }
            .padding(.bottom, .grid(2))
          }
          
          if viewStore.hasOfflineError {
            offlineBanner()
              .clipShape(Circle())
              .opacity(showOfflineBanner ? 1 : 0)
              .accessibleAnimation(.easeInOut(duration: 0.2), value: showOfflineBanner)
          }
        }
        .padding(.top, .grid(1))

        Spacer()
      }
      .padding(.horizontal)

      VStack {
        Spacer()
        
        AppNavigationView(store: store)
          .accessibilitySortPriority(1)
          .padding(.horizontal)
          .padding(.bottom, .grid(7))
          .frame(maxWidth: 400)
      }
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .bottomSheet(
      bottomSheetPosition: viewStore.binding(
        get: \.bottomSheetPosition,
        send: { .binding(.set(\.$bottomSheetPosition, $0)) }
      ),
      switchablePositions: [
        .relative(0.4),
        .relativeTop(0.975)
      ],
      title: "Events",
      content: { bottomSheetContentView() }
    )
    .showCloseButton()
    .backgroundBlurMaterial(.adaptive(.thin))
    .showDragIndicator(true)
    .enableSwipeToDismiss()
    .onDismiss { viewStore.send(.set(\.$bottomSheetPosition, .hidden)) }
//    .alert(store.scope(state: \.alert, action: { $0 }), dismiss: .dismissAlert)
    .onAppear { viewStore.send(.onAppear) }
    .onDisappear { viewStore.send(.onDisappear) }
  }

  @ViewBuilder
  func infoContent() -> some View {
    if showsInfoExpanded {
      VStack {
        Text("Info")
          .foregroundColor(Color(.textPrimary))
          .font(.titleTwo)
        
        DataTile("Next update") {
          CircularProgressView(progress: viewStore.timerProgress)
            .frame(width: 44, height: 44)
            .overlay(alignment: .center) {
              if viewStore.isRequestingRiderLocations {
                ProgressView()
              } else {
                Text(verbatim: viewStore.timerValue)
                  .foregroundColor(Color(.textPrimary))
                  .font(.system(size: 14).bold())
                  .monospacedDigit()
              }
            }
            .padding(.top, .grid(1))
        }
  
        DataTile("Riders") {
          HStack {
            Text(viewStore.ridersCount)
              .font(.pageTitle)
          }
          .foregroundColor(Color(.textPrimary))
        }
      }
      .transition(
        .asymmetric(
          insertion: .opacity.combined(with: .scale(scale: 1, anchor: .topLeading)).animation(.easeIn(duration: 0.2)),
          removal: .opacity.combined(with: .scale(scale: 0, anchor: .topLeading)).animation(.easeIn(duration: 0.12))
        )
      )
      .contentShape(Rectangle())
      .onTapGesture {
        withAnimation { showsInfoExpanded = false }
      }
    } else {
      Button(action: { withAnimation { showsInfoExpanded = true } }) {
        Image(systemName: "info.circle")
          .resizable()
          .frame(width: 30, height: 30)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .scale(scale: 0, anchor: .bottomLeading)).animation(.easeIn(duration: 0.1)),
              removal: .opacity.animation(.easeIn(duration: 0.1))
            )
          )
      }
    }
  }
  
  @ViewBuilder
  func bottomSheetContentView() -> some View {
    VStack {
      List(viewStore.nextRideState.rideEvents, id: \.id) { ride in
        HStack(alignment: .center, spacing: .grid(2)) {
          Image(uiImage: Asset.cm.image)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: .grid(1)) {
            Text(ride.title)
              .multilineTextAlignment(.leading)
              .font(Font.body.weight(.semibold))
              .foregroundColor(Color(.textPrimary))
              .padding(.bottom, .grid(1))

            VStack(alignment: .leading, spacing: 2) {
              Label(ride.dateTime.humanReadableDate, systemImage: "calendar")
                .multilineTextAlignment(.leading)
                .font(.bodyTwo)
                .foregroundColor(Color(.textSecondary))

              Label(ride.dateTime.humanReadableTime, systemImage: "clock")
                .multilineTextAlignment(.leading)
                .font(.bodyTwo)
                .foregroundColor(Color(.textSecondary))

              if let location = ride.location {
                Label(location, systemImage: "location.fill")
                  .multilineTextAlignment(.leading)
                  .font(.bodyTwo)
                  .foregroundColor(Color(.textSecondary))
              }
            }
          }
          Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, .grid(1))
        .accessibilityElement(children: .combine)
        .onTapGesture {
          viewStore.send(.onRideSelectedFromBottomSheet(ride))
        }
        .listRowBackground(Color.clear)
      }
      .listStyle(.plain)
    }
    .accessibilityAction(.escape) {
      viewStore.send(.set(\.$bottomSheetPosition, .hidden))
    }
  }

  @ViewBuilder
  func offlineBanner() -> some View {
    Image(systemName: "wifi.slash")
      .foregroundColor(
        reduceTransparency
          ? Color.white
          : Color(.attention)
      )
      .accessibilityLabel(Text("Internet not available"))
      .padding()
      .background(
        Group {
          if reduceTransparency {
            RoundedRectangle(
              cornerRadius: 8,
              style: .circular
            )
            .fill(reduceTransparency
              ? Color(.attention)
              : Color(.attention).opacity(0.8)
            )
          } else {
            Blur()
          }
        }
      )
  }

  @ViewBuilder
  func nextRideBanner() -> some View {
    MapOverlayView(
      store: store.scope(
        state: {
          MapOverlayView.ViewState(
            isVisible: $0.mapFeatureState.isNextRideBannerVisible,
            isExpanded: $0.mapFeatureState.isNextRideBannerExpanded
          )
        },
        action: { $0 }
      ),
      action: { viewStore.send(.map(.focusNextRide(viewStore.nextRideState.nextRide?.coordinate))) },
      content: {
        VStack(alignment: .leading, spacing: .grid(1)) {
          Text(viewStore.state.nextRideState.nextRide?.title ?? "")
            .multilineTextAlignment(.leading)
            .font(.titleTwo)
            .foregroundColor(Color(.textPrimary))
          Text(viewStore.state.nextRideState.nextRide?.rideDateAndTime ?? "")
            .multilineTextAlignment(.leading)
            .font(.bodyTwo)
            .foregroundColor(Color(.textSecondary))
        }
      }
    )
    .accessibilityElement(children: .contain)
    .accessibilityHint(Text(L10n.A11y.Mapfeatureview.Nextridebanner.hint))
    .accessibilityLabel(Text(L10n.A11y.Mapfeatureview.Nextridebanner.label))
  }
}

// MARK: Preview

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(
      store: Store(initialState: .init()) { AppFeature() }
    )
  }
}
