//
//  LocationManager.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/13/25.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    @Published var locationErrorMessage: String?

    var manager = CLLocationManager()

    func checkLocationAuthorization() {
        manager.delegate = self
        manager.startUpdatingLocation()

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .restricted:
            locationErrorMessage = "Location use is restricted"
            
        case .denied:
            locationErrorMessage = "Location access was denied. Please enable it in Settings."
            
        case .authorizedAlways:
            locationErrorMessage = nil
            print("Location authorizedAlways")
            
        case .authorizedWhenInUse:
            locationErrorMessage = nil
            lastKnownLocation = manager.location?.coordinate

        @unknown default:
            locationErrorMessage = "Unknown location authorization status"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
}
