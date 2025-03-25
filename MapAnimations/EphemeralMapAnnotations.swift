//
//  EphemeralMapAnnotations.swift
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

// MARK: Animation constants
private enum EphAnimationConstants {
    static let duration: CGFloat = 0.5
    static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    static let removingAnimaton = Animation.easeInOut(duration: duration)
}

// MARK: Protocols

protocol EphRepresentable: Hashable, Equatable {
    var id: Int { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

protocol EphRepresentableProvider {
    associatedtype EphRepresentableType: EphRepresentable
    var places: [EphRepresentableType] { get set }
}

// MARK: Annotation supplements
/**
 The encapsulation of a Place and it's associated booleans that determine how it will be animated in the next rendering of the Map that contains it.
 */
class EphAnnotationState<P: EphRepresentable>: ObservableObject {
    let place: P
    @Published var isVisible: Bool
    @Published var isRemoving: Bool

    /**
     Initializes a new AnnotationState

     - Parameter place: The Place object represented by this AnnotationState.
     - Parameter isVisible: When true, the place will be visible on the Map
     - Parameter isRemoving: When true, the place will be removed from the Map
     */
    init(place: P, isVisible: Bool = false, isRemoving: Bool = false) {
        self.place = place
        self.isVisible = isVisible
        self.isRemoving = isRemoving
    }
}

struct EphAnnotationView<P: EphRepresentable>: View {
    @ObservedObject var annotationState: EphAnnotationState<P>

    var body: some View {
        let color: Color = annotationState.isRemoving ? .red : (annotationState.isVisible ? .blue : .green)

        Image(systemName: "circle.fill")
            .foregroundColor(color)
            .opacity(annotationState.isVisible ? 1 : 0)
            .scaleEffect(annotationState.isVisible ? 1 : 0)
            .animation(annotationState.isRemoving ? EphAnimationConstants.removingAnimaton : EphAnimationConstants.addingAnimation, value: annotationState.isVisible)
            .onAppear {
                if !annotationState.isRemoving {
                    annotationState.isVisible = true
                }
            }
    }
}

// MARK: View Modifier

struct EphRepresentableChangeModifier<Provider: EphRepresentableProvider>: ViewModifier {
    let provider: Provider
    @Binding var previousPlaces: [Provider.EphRepresentableType]?
    @Binding var annotationStates: [EphAnnotationState<Provider.EphRepresentableType>]

    func body(content: Content) -> some View {
        content
            .onChange(of: provider.places) { _, newPlaces in
                guard let previousPlaces = self.previousPlaces else {
                    self.previousPlaces = newPlaces
                    annotationStates = newPlaces.map { EphAnnotationState(place: $0) }
                    return
                }

                let currentIds = Set(newPlaces.map { $0.id })
                let oldIds = Set(previousPlaces.map { $0.id })

                // First, add new states immediately
                let newStates = newPlaces.filter { !oldIds.contains($0.id) }
                    .map { EphAnnotationState(place: $0) }
                annotationStates.append(contentsOf: newStates)

                // Then mark states for removal
                for state in annotationStates where !currentIds.contains(state.place.id) {
                    state.isRemoving = true
                    state.isVisible = false
                }

                // Clean up removed states after animation
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(EphAnimationConstants.duration))
                    annotationStates.removeAll { !currentIds.contains($0.place.id) }
                }

                self.previousPlaces = newPlaces
            }
    }
}

// MARK: The View Extension for the Modifier

extension View {
    func onEphRepresentableChange<Provider: EphRepresentableProvider>(
        provider: Provider,
        previousPlaces: Binding<[Provider.EphRepresentableType]?>,
        annotationStates: Binding<[EphAnnotationState<Provider.EphRepresentableType>]>
    ) -> some View {
        modifier(EphRepresentableChangeModifier(
            provider: provider,
            previousPlaces: previousPlaces,
            annotationStates: annotationStates
        ))
    }
}
