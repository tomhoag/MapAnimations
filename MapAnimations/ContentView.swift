//
//  ContentView.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit
import MichiganCities

extension MichiganCity: EphRepresentable {
    // EphRepresentable requires conformance to Identifiable and Equatable.
    // Since MichiganCity already conforms to these two protocols, there is nothing
    // needed here.
}

// Add an extension for when ER is MichiganCity
extension EphemeralAnnotation where ER == MichiganCity {
    @MapContentBuilder
    var body: some MapContent {
        Annotation(state.place.name, coordinate: state.place.coordinate) {
            content()
                .ephemeralEffect(annotationState: state)
        }
    }
}

struct ContentView: View, EphRepresentableProvider {

    // MARK: EphRepresentableProvider
    @State var ephemeralPlaces: [MichiganCity] = []
    @State var stateManager = EphStateManager<MichiganCity>()

    // MARK: ContentView state
    @State var cameraPosition: MapCameraPosition = .automatic
    @State private var buttonScale: CGFloat = 1.0

    // MARK: vars and funcs for map and UI
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
                ForEach(stateManager.annotationStates, id: \.place.id) { state in
                    Annotation(state.place.name, coordinate: state.place.coordinate) {
                        Circle()
                            .frame(width: 20)
                            .foregroundColor(.red)
                            .ephemeralEffect(annotationState: state)
                    }
                }
            }
            .onEphRepresentableChange( provider: self )
            .padding()
            .onAppear {
                Task { @MainActor in
                    updatePlaces()
                    cameraPosition = .region(mapRegion)
                }
            }

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

    func updatePlaces() {
        self.ephemeralPlaces = MichiganCities.random(count: 25)!
    }
}

#Preview {
    ContentView()
}
