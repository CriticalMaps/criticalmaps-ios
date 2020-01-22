//
//  BikeAnnotationController.swift
//  CriticalMaps
//
//  Created by Leonard Thomas on 14.11.19.
//  Copyright © 2019 Pokus Labs. All rights reserved.
//

import MapKit

class BikeAnnotation: IdentifiableAnnnotation {}

class BikeAnnotationController: AnnotationController<BikeAnnotation, BikeAnnoationView> {
    private var friendsVerificationController: FriendsVerificationController

    init(friendsVerificationController: FriendsVerificationController, mapView: MKMapView) {
        self.friendsVerificationController = friendsVerificationController
        super.init(mapView: mapView)
    }

    required init(mapView _: MKMapView) {
        fatalError("init(mapView:) has not been implemented")
    }

    public override func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(positionsDidChange(notification:)), name: Notification.positionOthersChanged, object: nil)
    }

    @objc private func positionsDidChange(notification: Notification) {
        guard let response = notification.object as? ApiResponse else { return }
        display(locations: response.locations)
    }

    private func display(locations: [String: Location]) {
        guard LocationManager.accessPermission == .authorized else {
            Logger.log(.info, log: .map, "Bike annotations cannot be displayed because no GPS Access permission granted", parameter: LocationManager.accessPermission.rawValue)
            return
        }
        var filtredLocations = locations

        if Feature.friends.isActive {
            filtredLocations = filtredLocations.filter { !friendsVerificationController.isFriend(id: $0.key) }
        }

        updateAnnotations(locations: filtredLocations)
    }
}
