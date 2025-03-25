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

/**
 A protocol that describes the information needed about each location that will be animated as it is added or removed.

 - Note that this protocol abides by Equatable and Hashable.  Accordingly, any struct that adopts this protocol must also
 conform to Equatable and Hashable

 ```
 struct MichiganCity: EphRepresentable {

     static func == (lhs: MichiganCity, rhs: MichiganCity) -> Bool { // <-- Equatable
         lhs.id == rhs.id
     }

     func hash(into hasher: inout Hasher) { // <-- Hashable
         hasher.combine(id)
     }

     var id: Int // <-- reqd by EphRepresentable protocol
     var coordinate: CLLocationCoordinate2D // <-- reqd by EphRepresentable protocol

    var name: String // <-- other property

 }
```
 */
protocol EphRepresentable: Hashable, Equatable {
    var id: Int { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

/**
 The protocol that must be adopted by the struct/class that will be providing the EphRepresentable instances.
 The `associatedtype`  allow fors generic flexibility.

 The protocol defines what a provider must do (provide places), but it doesn't specify exactly what kind of places.
 The `associatedtype` lets each implementation of the protocol decide its specific place type.

    - One provider might work with cities (MichiganCity)
    - Another might work with parks (StatePark)
    - Another with restaurants (Restaurant)

 - Code Example:

 `ContentView.swift` is providing the EphRepresentables as type MichiganCity:

 ```
 struct ContentView: View, EphRepresentableProvider {
     typealias EphRepresentableType = MichiganCity
     @State var places: [EphRepresentableType] = []
```
 */
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
