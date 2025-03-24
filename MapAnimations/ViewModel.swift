//
//  ViewModel.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/24/25.
//

import SwiftUI
import MapKit

struct Place: PlaceProtocol {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    var id: Int
    var name: String
    var coordinate: CLLocationCoordinate2D
}

@Observable
class ViewModel: PlacesViewModel {
    typealias PlaceType = Place
    var places: [PlaceType] = []
    var useFirst = true

    static let baycity = Place(id: 1, name: "Bay City", coordinate: CLLocationCoordinate2D(latitude: 43.592846, longitude: -83.894348))

    func update() {

        var places: [Place] = []

        if useFirst {
            places = [
                Place(id: 2, name: "Grand Haven", coordinate: CLLocationCoordinate2D(latitude:    43.062244, longitude:    -86.230759)),
                Place(id: 3, name: "Escanaba", coordinate: CLLocationCoordinate2D(latitude: 45.745312, longitude:    -87.070457)),
                Place(id: 4, name: "Ecorse", coordinate: CLLocationCoordinate2D(latitude:42.249313, longitude:    -83.151329)),
                Place(id: 5, name: "Eastpointe", coordinate: CLLocationCoordinate2D(latitude:42.466595, longitude:    -82.959213)),
                ViewModel.baycity
            ]
        } else {
            places = [
                Place(id: 6, name: "Charlevoix", coordinate: CLLocationCoordinate2D(latitude:45.317806, longitude:    -85.262009)),
                Place(id: 7, name: "Bloomfield Hills", coordinate: CLLocationCoordinate2D(latitude:42.583652, longitude:    -83.248009)),
                Place(id: 8, name: "Benton Harbor", coordinate: CLLocationCoordinate2D(latitude: 42.116463, longitude:    -86.457497)),
                ViewModel.baycity
            ]
        }
        useFirst.toggle()
        self.places = places
    }

    var mapRegion: MKCoordinateRegion {

        let locations = self.places.map {
            $0.coordinate
        }

        guard !locations.isEmpty else {
            let center = CLLocationCoordinate2D(
                latitude: 0,
                longitude: 0
            )
            let span = MKCoordinateSpan(latitudeDelta: 1000, longitudeDelta: 1000)
            return MKCoordinateRegion(center: center, span: span)
        }

        var minLat = locations[0].latitude
        var maxLat = locations[0].latitude
        var minLon = locations[0].longitude
        var maxLon = locations[0].longitude

        for location in locations {
            if location.latitude < minLat {
                minLat = location.latitude
            }
            if location.latitude > maxLat {
                maxLat = location.latitude
            }
            if location.longitude < minLon {
                minLon = location.longitude
            }
            if location.longitude > maxLon {
                maxLon = location.longitude
            }
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.25 // Add some padding
        let spanLon = (maxLon - minLon) * 1.25 // Add some padding

        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        //    let center = CLLocationCoordinate2D(latitude: group.coordinate.latitude, longitude: group.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)

        return MKCoordinateRegion(center: center, span: span)
    }
}
