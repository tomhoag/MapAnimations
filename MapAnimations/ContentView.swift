//
//  ContentView.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit



struct ContentView: View {
    @State var cameraPosition: MapCameraPosition = .automatic
    var viewModel = ViewModel()

    @State private var buttonScale: CGFloat = 1.0
    @State private var previousPlaces: [Place]?
    @State private var annotationStates: [AnnotationState<Place>] = []

    var body: some View {
        VStack {
            Button("Drink Me") {
                viewModel.update()
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
                        AnnotationView<Place>(annotationState: state)
                    }
                }
            }
            .padding()
            .onAppear {
                Task { @MainActor in
                    viewModel.update()
                    cameraPosition = .region(viewModel.mapRegion)
                }
            }
            .onPlacesChange(
                viewModel: viewModel,
                previousPlaces: $previousPlaces,
                annotationStates: $annotationStates
            )
        }
    }
}

#Preview {
    ContentView()
}
