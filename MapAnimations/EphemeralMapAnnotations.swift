//
//  EphemeralMapAnnotations.swift
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

/**
 Constants used for animation timing and behavior throughout the ephemeral annotation system.
 */
private enum EphAnimationConstants {
    /// Duration of animations in seconds
    static let duration: CGFloat = 0.5
    /// Spring animation used when adding annotations
    static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    /// Ease in-out animation used when removing annotations
    static let removingAnimaton = Animation.easeInOut(duration: duration)
}

/**
 Base protocol defining read-only requirements for map annotations.

 This protocol provides the fundamental properties needed to identify and position
 an annotation on a map. It requires conformance to `Hashable` and `Equatable`
 for unique identification and comparison of annotations.
 */
protocol EphDerivable: Hashable, Equatable {
    var id: Int { get }
    var coordinate: CLLocationCoordinate2D { get }
}

/**
 Protocol defining mutable requirements for map annotations.

 Extends `EphDerivable` to add mutability to the base properties, allowing
 annotations to be updated during their lifecycle.
 */
protocol EphRepresentable: EphDerivable {
    var id: Int { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

/**
 Protocol for types that provide collections of map annotations.

 Implementing types must specify the concrete type of annotations they provide
 through the associated type `EphRepresentableType`.

 Example implementation:
 ```swift
 struct MyProvider: EphRepresentableProvider {
     typealias EphRepresentableType = MyAnnotationType
     @State var places: [MyAnnotationType] = []
 }
 ```
 */
protocol EphRepresentableProvider {
    associatedtype EphRepresentableType: EphRepresentable
    var places: [EphRepresentableType] { get set }
}

/**
 Class managing the visibility state of a map annotation.

 This observable class tracks whether an annotation should be visible on the map
 and whether it's in the process of being removed. It works in conjunction with
 animation modifiers to provide smooth transitions.

 - Important: This class is ObservableObject and can be used with @StateObject or @ObservedObject.
 Changing to @Observable is not recommended as it leads to unexpected behavior.
 */
class EphAnnotationState<P: EphRepresentable>: ObservableObject {
    /// The annotation being managed
    let place: P
    /// Current visibility state
    @Published var isVisible: Bool
    /// Whether the annotation is being removed
    @Published var isRemoving: Bool

    /**
     Creates a new annotation state.

     - Parameters:
        - place: The annotation to manage
        - isVisible: Initial visibility state
        - isRemoving: Initial removal state
     */
    init(place: P, isVisible: Bool = false, isRemoving: Bool = false) {
        self.place = place
        self.isVisible = isVisible
        self.isRemoving = isRemoving
    }
}

/**
 ViewModifier that manages the lifecycle of map annotations.

 Handles the addition and removal of annotations with appropriate animations.
 Automatically cleans up removed annotations after their exit animation completes.
 */
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

                let newStates = newPlaces.filter { !oldIds.contains($0.id) }
                    .map { EphAnnotationState(place: $0) }
                annotationStates.append(contentsOf: newStates)

                for state in annotationStates where !currentIds.contains(state.place.id) {
                    state.isRemoving = true
                    state.isVisible = false
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(EphAnimationConstants.duration))
                    annotationStates.removeAll { !currentIds.contains($0.place.id) }
                }

                self.previousPlaces = newPlaces
            }
    }
}

/**
 ViewModifier that applies ephemeral animation effects to a view.

 Handles the fade in/out and scale animations for views as they appear and disappear.
 */
struct EphemeralEffect<P: EphRepresentable>: ViewModifier {
    @ObservedObject var annotationState: EphAnnotationState<P>

    func body(content: Content) -> some View {
        content
            .opacity(annotationState.isVisible ? 1 : 0)
            .scaleEffect(annotationState.isVisible ? 1 : 0)
            .animation(
                annotationState.isRemoving ?
                    EphAnimationConstants.removingAnimaton :
                    EphAnimationConstants.addingAnimation,
                value: annotationState.isVisible
            )
            .onAppear {
                if !annotationState.isRemoving {
                    annotationState.isVisible = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /**
     Applies the ephemeral map annotation change modifier to a view.

     - Parameters:
        - provider: The source of annotation data
        - previousPlaces: Binding to track the previous state of annotations
        - annotationStates: Binding to the current annotation states
     */
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

    /**
     Applies ephemeral animation effects to a view.

     - Parameter annotationState: The state controlling the view's animations
     */
    func ephemeralEffect<P: EphRepresentable>(annotationState: EphAnnotationState<P>) -> some View {
        modifier(EphemeralEffect(annotationState: annotationState))
    }
}
