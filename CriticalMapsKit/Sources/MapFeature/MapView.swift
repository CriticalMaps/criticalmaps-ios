//
//  File.swift
//  
//
//  Created by Malte on 15.06.21.
//

import Foundation
import Logger
import MapKit
import NextRideFeature
import SharedModels
import Styleguide
import SwiftUI

public typealias ViewRepresentable = UIViewRepresentable

struct MapView: ViewRepresentable {
  var riderCoordinates: [Rider]
  @Binding var userTrackingMode: MKUserTrackingMode
  var shouldAnimateUserTrackingMode: Bool
  var nextRide: Ride?
  
  func makeCoordinator() -> MapCoordinator {
    MapCoordinator(self)
  }
  
  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView(frame: UIScreen.main.bounds)
    mapView.mapType = .mutedStandard
    mapView.pointOfInterestFilter = .excludingAll
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = true
    mapView.register(annotationViewType: RiderAnnoationView.self)
    mapView.register(annotationViewType: CMMarkerAnnotationView.self)
    return mapView
  }
  
  func updateUIView(_ uiView: MKMapView, context: Context) {
    uiView.setUserTrackingMode(userTrackingMode, animated: shouldAnimateUserTrackingMode)
  
    let updatedAnnotations = RiderAnnotationUpdateClient.update(riderCoordinates, uiView)
    
    uiView.removeAnnotations(updatedAnnotations.removedAnnotations)
    uiView.addAnnotations(updatedAnnotations.addedAnnotations)
    
    if let nextRide = nextRide {
      if uiView.annotations.compactMap({ $0 as? CriticalMassAnnotation }).isEmpty {
        let nextRideAnnotation = CriticalMassAnnotation(ride: nextRide)
        guard nextRide.coordinate != nil else { return }
        uiView.addAnnotation(nextRideAnnotation!)
      }
    }
  }
}

public class MapCoordinator: NSObject, MKMapViewDelegate {
  var parent: MapView
  
  init(_ parent: MapView) {
    self.parent = parent
  }
  
  public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
    parent.userTrackingMode = mode
  }
    
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is MKUserLocation == false else {
        return nil
    }
    if annotation is RiderAnnotation {
      let view = mapView.dequeueReusableAnnotationView(
        withIdentifier: RiderAnnoationView.reuseIdentifier,
        for: annotation
      )
      return view as! RiderAnnoationView
    }
    
    if annotation is CriticalMassAnnotation {
      let view = mapView.dequeueReusableAnnotationView(
        withIdentifier: CMMarkerAnnotationView.reuseIdentifier,
        for: annotation
      )
      return view
    }
    
    return MKAnnotationView()
  }
}
