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
    static let removingAnimation = Animation.easeInOut(duration: duration)
}

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

/**
 ViewModifier that manages the lifecycle of map annotations.

 Handles the addition and removal of annotations with appropriate animations.
 Automatically cleans up removed annotations after their exit animation completes.
 */
struct EphRepresentableChangeModifier<Provider: EphRepresentableProvider>: ViewModifier {
    let provider: Provider
    var animationDuration: CGFloat = EphAnimationConstants.duration
    @State private var cleanupTasks: Set<Task<Void, Never>> = []

    func body(content: Content) -> some View {
        content
            .onChange(of: provider.ephemeralPlaces) { _, newPlaces in
                guard let previousPlaces = provider.stateManager.previousPlaces else {
                    provider.stateManager.previousPlaces = newPlaces
                    provider.stateManager.annotationStates = newPlaces.map { EphAnnotationState(place: $0) }
                    return
                }

                let changes = calculateChanges(oldPlaces: previousPlaces, newPlaces: newPlaces)

                // Add new states
                provider.stateManager.annotationStates.append(contentsOf: changes.toAdd.map { EphAnnotationState(place: $0) })

                // Mark states for removal
                for state in provider.stateManager.annotationStates where changes.toRemove.contains(state.place.id) {
                    state.prepareForRemoval()
                }

                // Cancel and remove existing tasks
                cleanupTasks.forEach { $0.cancel() }
                cleanupTasks.removeAll()

                // Start new cleanup
                let task = Task {
                    try? await Task.sleep(for: .seconds(animationDuration))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        provider.stateManager.annotationStates.removeAll { changes.toRemove.contains($0.place.id) }
                    }
                }
                cleanupTasks.insert(task)

                provider.stateManager.previousPlaces = newPlaces
            }
            .onDisappear {
                cleanupTasks.forEach { $0.cancel() }
                cleanupTasks.removeAll()
            }
    }

    private struct Changes {
        let toAdd: [Provider.EphRepresentableType]
        let toRemove: Set<Int>
    }

    private func calculateChanges(
        oldPlaces: [Provider.EphRepresentableType],
        newPlaces: [Provider.EphRepresentableType]
    ) -> Changes {
        let oldIds = Dictionary(uniqueKeysWithValues: oldPlaces.map { ($0.id, $0) })
        let newIds = Dictionary(uniqueKeysWithValues: newPlaces.map { ($0.id, $0) })

        let toAdd = newPlaces.filter { !oldIds.keys.contains($0.id) }
        let toRemove = Set(oldIds.keys).subtracting(newIds.keys)

        return Changes(toAdd: toAdd, toRemove: toRemove)
    }
}

/**
 ViewModifier that applies ephemeral animation effects to a view.

 Handles the fade in/out and scale animations for views as they appear and disappear.
 */
struct EphemeralEffectModifier<P: EphRepresentable>: ViewModifier {
    @ObservedObject var annotationState: EphAnnotationState<P>
    var addingAnimation: Animation = EphAnimationConstants.addingAnimation
    var removingAnimation: Animation = EphAnimationConstants.removingAnimation

    func body(content: Content) -> some View {
        content
            .opacity(annotationState.isVisible ? 1 : 0)
            .scaleEffect(annotationState.isVisible ? 1 : 0)
            .animation(
                annotationState.isRemoving ?
                    removingAnimation :
                    addingAnimation,
                value: annotationState.isVisible
            )
            .onAppear {
                if !annotationState.isRemoving {
                    annotationState.makeVisible()
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
        - animationDuration: The duration of the longer of the two (adding, removing) animations used in the ephemeralEffect modifier. If no animations are specified there, this parameter should not be passed in.
     */
    func onEphRepresentableChange<Provider: EphRepresentableProvider>(
        provider: Provider,
        animationDuration: CGFloat = EphAnimationConstants.duration
    ) -> some View {
        modifier(EphRepresentableChangeModifier(
            provider: provider,
            animationDuration: animationDuration
        ))
    }

    /**
     Applies ephemeral animation effects to a view.

     - Parameter annotationState: The state controlling the view's animations
     */
    func ephemeralEffect<P: EphRepresentable>(
        annotationState: EphAnnotationState<P>,
        addingAnimation: Animation = EphAnimationConstants.addingAnimation,
        removingAnimation: Animation = EphAnimationConstants.removingAnimation
    ) -> some View {
        modifier(
            EphemeralEffectModifier(
                annotationState: annotationState,
                addingAnimation: addingAnimation,
                removingAnimation: removingAnimation
            )
        )
    }
}
