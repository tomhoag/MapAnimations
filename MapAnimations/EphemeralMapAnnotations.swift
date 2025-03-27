//
//  EphemeralMapAnnotations.swift
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

/**
 Protocol defining mutable requirements for map annotations.

 Extends `EphDerivable` to add mutability to the base properties, allowing
 annotations to be updated during their lifecycle.
 */
protocol EphRepresentable: Equatable {
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
    var ephemeralPlaces: [EphRepresentableType] { get set }
    var stateManager: EphStateManager<EphRepresentableType> { get }
}

@MainActor @Observable
class EphStateManager<ER: EphRepresentable>: ObservableObject {
    var previousPlaces: [ER]?
    var annotationStates: [EphAnnotationState<ER>] = []
}

/**
 Class managing the visibility state of a map annotation.

 This observable class tracks whether an annotation should be visible on the map
 and whether it's in the process of being removed. It works in conjunction with
 animation modifiers to provide smooth transitions.

 - Important: This class is ObservableObject and can be used with @StateObject or @ObservedObject.
 Changing to @Observable leads to unexpected behavior.
 */
class EphAnnotationState<P: EphRepresentable>: ObservableObject {
    /// The annotation being managed
    let place: P
    /// Current visibility state
    @Published private(set) var isVisible: Bool
    /// Whether the annotation is being removed
    @Published private(set) var isRemoving: Bool

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

    func makeVisible() {
        isVisible = true
    }

    func makeInvisible() {
        isVisible = false
    }

    func prepareForRemoval() {
        isRemoving = true
        makeInvisible()
    }
}
