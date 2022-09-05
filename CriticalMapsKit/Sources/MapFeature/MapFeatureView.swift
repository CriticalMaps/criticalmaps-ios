import ComposableArchitecture
import Helpers
import L10n
import SharedEnvironment
import SharedModels
import Styleguide
import SwiftUI

public struct MapFeatureView: View {
  @Environment(\.accessibilityReduceTransparency) var reduceTransparency
  @Environment(\.connectivity) var isConnected

  public init(store: Store<MapFeature.State, MapFeature.Action>) {
    self.store = store
    viewStore = ViewStore(store)
  }

  let store: Store<MapFeature.State, MapFeature.Action>
  @ObservedObject var viewStore: ViewStore<MapFeature.State, MapFeature.Action>

  public var body: some View {
    ZStack(alignment: .topLeading) {
      MapView(
        riderCoordinates: viewStore.riderLocations,
        userTrackingMode: viewStore.binding(\.$userTrackingMode),
        shouldAnimateUserTrackingMode: viewStore.shouldAnimateTrackingMode,
        nextRide: viewStore.nextRide,
        rideEvents: viewStore.rideEvents,
        centerRegion: viewStore.binding(\.$centerRegion),
        centerEventRegion: viewStore.binding(\.$eventCenter),
        mapMenuShareEventHandler: {
          viewStore.send(.showShareSheet(true))
        },
        mapMenuRouteEventHandler: {
          viewStore.send(.routeToEvent)
        }
      )
      .edgesIgnoringSafeArea(.all)
    }
    .sheet(
      isPresented: viewStore.binding(\.$presentShareSheet),
      onDismiss: { viewStore.send(.showShareSheet(false)) },
      content: {
        ShareSheetView(activityItems: [viewStore.nextRide?.shareMessage ?? ""])
      }
    )
  }
}

// MARK: Preview

struct MapFeatureView_Previews: PreviewProvider {
  static var previews: some View {
    MapFeatureView(
      store: Store<MapFeature.State, MapFeature.Action>(
        initialState: MapFeature.State(
          riders: [],
          userTrackingMode: UserTrackingState(userTrackingMode: .follow)
        ),
        reducer: MapFeature.reducer,
        environment: MapFeature.Environment(
          locationManager: .live,
          mainQueue: .failing
        )
      )
    )
  }
}
