//
//  ContentView.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

// Animation constants
private enum AnimationConstants {
    static let duration: CGFloat = 0.5
    static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    static let removingAnimaton = Animation.easeInOut(duration: duration)
}

class AnnotationState: ObservableObject {

    let place: Place
    @Published var isVisible: Bool
    @Published var isRemoving: Bool

    init(place: Place, isVisible: Bool = false, isRemoving: Bool = false) {
        self.place = place
        self.isVisible = isVisible
        self.isRemoving = isRemoving
    }
}

struct AnnotationView: View {
    @ObservedObject var annotationState: AnnotationState

    var body: some View {
        let color: Color = annotationState.isRemoving ? .red : (annotationState.isVisible ? .blue : .green)

        Image(systemName: "circle.fill")
            .foregroundColor(color)
            .opacity(annotationState.isVisible ? 1 : 0)
            .scaleEffect(annotationState.isVisible ? 1 : 0)
            .animation(annotationState.isRemoving ? AnimationConstants.removingAnimaton : AnimationConstants.addingAnimation, value: annotationState.isVisible)
            .onAppear {
                if !annotationState.isRemoving {
                    annotationState.isVisible = true
                }
            }
    }
}

struct ContentView: View {
    @State var cameraPosition: MapCameraPosition = .automatic
    var viewModel = ViewModel()

    @State private var buttonScale: CGFloat = 1.0
    @State private var previousPlaces: [Place]?
    @State private var annotationStates: [AnnotationState] = []

    var body: some View {
        VStack {
            Button("Drink Me") {
                viewModel.update()
                withAnimation(.easeInOut(duration: AnimationConstants.duration)) {
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
                        AnnotationView(annotationState: state)
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
            .onChange(of: viewModel.places) { _, newPlaces in

                guard let previousPlaces = self.previousPlaces else {
                    self.previousPlaces = newPlaces
                    annotationStates = newPlaces.map { AnnotationState(place: $0) }
                    return
                }

                let currentIds = Set(newPlaces.map { $0.id })
                let oldIds = Set(previousPlaces.map { $0.id })

                // First, add new states immediately
                let newStates = newPlaces.filter { !oldIds.contains($0.id) }
                    .map { AnnotationState(place: $0) }
                annotationStates.append(contentsOf: newStates)

                // Then mark states for removal
                for state in annotationStates where !currentIds.contains(state.place.id) {
                    state.isRemoving = true
                    state.isVisible = false
                }

                // Clean up removed states after animation
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(AnimationConstants.duration))
                    annotationStates.removeAll { !currentIds.contains($0.place.id) }
                }

                self.previousPlaces = newPlaces
            }
        }
    }
}

#Preview {
    ContentView()
}
