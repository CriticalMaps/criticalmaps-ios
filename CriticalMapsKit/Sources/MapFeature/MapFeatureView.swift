import ComposableArchitecture
import Helpers
import L10n
import SharedDependencies
import SharedModels
import Styleguide
import SwiftUI

public struct MapFeatureView: View {
  @Environment(\.accessibilityReduceTransparency) var reduceTransparency
  
  public init(store: StoreOf<MapFeature>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  let store: StoreOf<MapFeature>
  @ObservedObject var viewStore: ViewStoreOf<MapFeature>

  public var body: some View {
    ZStack(alignment: .topLeading) {
      MapView(
        riderCoordinates: viewStore.riderLocations,
        userTrackingMode: viewStore.binding(
          get: \.userTrackingMode,
          send: { .binding(.set(\.$userTrackingMode, $0)) }
        ),
        nextRide: viewStore.nextRide,
        rideEvents: viewStore.rideEvents,
        annotationsCount: viewStore.binding(
          get: \.visibleRidersCount,
          send: { .binding(.set(\.$visibleRidersCount, $0)) }
        ),
        centerRegion: viewStore.binding(
          get: \.centerRegion,
          send: { .binding(.set(\.$centerRegion, $0)) }
        ),
        centerEventRegion: viewStore.binding(
          get: \.eventCenter,
          send: { .binding(.set(\.$eventCenter, $0)) }
        ),
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
      isPresented: viewStore.binding(
        get: \.presentShareSheet,
        send: { .binding(.set(\.$presentShareSheet, $0)) }
      ),
      onDismiss: { viewStore.send(.showShareSheet(false)) },
      content: {
        ShareSheetView(activityItems: [viewStore.nextRide?.shareMessage ?? ""])
      }
    )
  }
}

// MARK: Preview

import SwiftUIHelpers

struct MapFeatureView_Previews: PreviewProvider {
  static var previews: some View {
    Preview {
      MapFeatureView(
        store: Store(
          initialState: MapFeature.State(
            riders: [],
            userTrackingMode: UserTrackingFeature.State(userTrackingMode: .follow)
          )
        ) { MapFeature()._printChanges() }
      )
    }
  }
}
