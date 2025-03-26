//
//  ContentView.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

struct ContentView: View, EphRepresentableProvider {
    @State var cameraPosition: MapCameraPosition = .automatic

    @State private var buttonScale: CGFloat = 1.0
    @State private var previousPlaces: [MichiganCity]?
    @State private var annotationStates: [EphAnnotationState<MichiganCity>] = []

    typealias EphRepresentableType = MichiganCity
    @State var places: [EphRepresentableType] = []

    func updatePlaces() {
        self.places = MichiganCities.random(count: 25)!
    }

    var body: some View {
        VStack {
            Button("Drink Me") {
                updatePlaces()
                withAnimation(.easeInOut(duration: 0.4999)) {
                    buttonScale = buttonScale < 0.5 ? 1.0 : 0
                }
            }

            HStack {
                ForEach(0...6, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                        .scaleEffect(buttonScale)
                        .animation(.easeInOut(duration: 0.5), value: buttonScale)
                }
            }

            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(annotationStates, id: \.place.id) { state in
                    Annotation(state.place.name, coordinate: state.place.coordinate) {
                        EphSystemImageAnnotationView<MichiganCity>(annotationState: state)
//                        EphAnnotationView(annotationState: state) {
//                            Circle()
//                                .foregroundColor(.green)
//                                .frame(width: 20)
//                        }
                    }
                }
            }
            .padding()
            .onAppear {
                Task { @MainActor in
                    updatePlaces()
                    cameraPosition = .region(mapRegion)
                }
            }
            .onEphRepresentableChange(
                provider: self,
                previousPlaces: $previousPlaces,
                annotationStates: $annotationStates
            )
        }
    }

    var mapRegion: MKCoordinateRegion {
        // Center point between both peninsulas
        let center = CLLocationCoordinate2D(
            latitude: 43.802819,
            longitude: -86.112938
        )
        
        // Span to show both peninsulas with some padding
        let span = MKCoordinateSpan(
            latitudeDelta: 6.0,
            longitudeDelta: 8.0
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    ContentView()
}
