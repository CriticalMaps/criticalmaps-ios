//
//  AnnotationController.swift
//  CriticalMaps
//
//  Created by Leonard Thomas on 15.11.19.
//  Copyright © 2019 Pokus Labs. All rights reserved.
//

import MapKit

class AnnotationController<T: IdentifiableAnnnotation, K: MKAnnotationView>: NSObject {
    var mapView: MKMapView
    let annotationType = T.self
    let annotationViewType = K.self

    required init(mapView: MKMapView) {
        self.mapView = mapView
        super.init()
    }

    open func setup() {
        mapView.register(annotationType: BikeAnnoationView.self)
    }
    
    open func prepareAnnotationView(annotation:T) -> K? {
        return nil
    }
}
