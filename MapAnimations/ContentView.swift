//
//  ContentView.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit


extension CLLocationCoordinate2D: @retroactive Hashable, @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct Place: Equatable, Hashable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }

    var id: Int
    var name: String
    var coordinate: CLLocationCoordinate2D
}

@Observable
class ViewModel {

    var places: [Place] = []
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

struct AnimatedAnnotationView: View {
    let color: Color
    let id: String
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0
    
    var body: some View {
        Image(systemName: "circle.fill")
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .font(.largeTitle)
            .task {
                print("[\(Date().timeIntervalSince1970)] Starting add animation for id: \(id)")
                // Use a slight delay to ensure view is ready
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1
                    scale = 1
                }
            }
    }
}

struct AnimatedRemovedAnnotationView: View {
    let color: Color
    let id: String
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        Image(systemName: "circle.fill")
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .font(.largeTitle)
            .task {
                print("[\(Date().timeIntervalSince1970)] Starting remove animation for id: \(id)")
                // Use a slight delay to ensure view is ready
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 0
                    scale = 0
                }
            }
    }
}

// Add this struct near the top of the file
struct AnimatedPlace: Identifiable {
    let id = UUID()  // Unique ID for each instance
    let place: Place
}

struct ContentView: View {

    @State var cameraPosition: MapCameraPosition = .automatic
    var viewModel = ViewModel()

    @State private var buttonScale: CGFloat = 0
    @State private var previousPlaces: [Place]?

    @State private var addedPlaces: [AnimatedPlace] = []
    @State private var removedPlaces: [AnimatedPlace] = []
    @State private var unchangedPlaces: [Place] = []

    var body: some View {
        VStack {
            Button("Drink Me") {
                viewModel.update()
                if buttonScale < 0.5 {
                    buttonScale = 1.0
                } else {
                    buttonScale = 0.2
                }
            }

            HStack {
                ForEach(0..<8) { _ in
                    Image(systemName: "circle.fill")
                        .foregroundColor(buttonScale < 0.5 ? .blue : .red)
                        .scaleEffect(buttonScale)
                        .animation(.easeIn(duration: 1.0), value: buttonScale)
                        .font(.largeTitle)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                buttonScale = 1
                            }
                        }
                }
            }

            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(unchangedPlaces, id: \.id) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .font(.largeTitle)
                    }
                }

                // Added places animate in (now using AnimatedPlace)
                ForEach(addedPlaces) { animatedPlace in
                    Annotation(animatedPlace.place.name, coordinate: animatedPlace.place.coordinate) {
                        AnimatedAnnotationView(color: .blue, id: animatedPlace.id.uuidString)
                    }
                }

                // Removed places animate out (now using AnimatedPlace)
                ForEach(removedPlaces) { animatedPlace in
                    Annotation(animatedPlace.place.name, coordinate: animatedPlace.place.coordinate) {
                        AnimatedRemovedAnnotationView(color: .blue, id: animatedPlace.id.uuidString)
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    viewModel.update()
                    cameraPosition = .region(viewModel.mapRegion)
                }
            }
            .onChange(of: viewModel.places) { _, newPlaces in
                guard let _ = self.previousPlaces else {
                    self.previousPlaces = newPlaces
                    addedPlaces = newPlaces.map { AnimatedPlace(place: $0) }
                    return
                }

                let addedIds = Set(newPlaces.map { $0.id })
                    .subtracting(previousPlaces!.map { $0.id })

                let removedIds = Set(previousPlaces!.map { $0.id })
                    .subtracting(newPlaces.map { $0.id })

                let unchangedIds = Set(newPlaces.map { $0.id })
                    .subtracting(addedIds)
                    .subtracting(removedIds)

                print("[\(Date().timeIntervalSince1970)] Added IDs: \(addedIds)")
                print("[\(Date().timeIntervalSince1970)] Removed IDs: \(removedIds)")

                unchangedPlaces = newPlaces.filter { unchangedIds.contains($0.id) }
                removedPlaces = previousPlaces!
                    .filter { removedIds.contains($0.id) }
                    .map { AnimatedPlace(place: $0) }
                addedPlaces = newPlaces
                    .filter { addedIds.contains($0.id) }
                    .map { AnimatedPlace(place: $0) }


                previousPlaces = newPlaces
            }
        }
    }
}

#Preview {
    ContentView()
}
