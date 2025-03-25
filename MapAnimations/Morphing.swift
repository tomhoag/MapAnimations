import SwiftUI
import MapKit

// MARK: Animation constants
private enum AnimationConstants {
    static let duration: CGFloat = 0.5
    static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    static let removingAnimaton = Animation.easeInOut(duration: duration)
}

// MARK: Protocols

protocol Place: Hashable, Equatable {
    var id: Int { get set }
    var name: String { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

protocol PlacesViewModel {
    associatedtype PlaceType: Place
    var places: [PlaceType] { get set }
}

// MARK: Annotation supplements
/**
 The encapsulation of a Place and it's associated booleans that determine how it will be animated in the next rendering of the Map that contains it.
 */
class AnnotationState<P: Place>: ObservableObject {
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

struct AnnotationView<P: Place>: View {
    @ObservedObject var annotationState: AnnotationState<P>

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

// MARK: View Modifier

struct PlacesChangeModifier<VM: PlacesViewModel>: ViewModifier {
    let viewModel: VM
    @Binding var previousPlaces: [VM.PlaceType]?
    @Binding var annotationStates: [AnnotationState<VM.PlaceType>]

    init(viewModel: VM, previousPlaces: Binding<[VM.PlaceType]?>, annotationStates: Binding<[AnnotationState<VM.PlaceType>]>) {
        self.viewModel = viewModel
        _previousPlaces = previousPlaces
        _annotationStates = annotationStates
    }

    func body(content: Content) -> some View {
        content
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

// MARK: Extensions

extension View {
    func onPlacesChange<VM: PlacesViewModel>(
        viewModel: VM,
        previousPlaces: Binding<[VM.PlaceType]?>,
        annotationStates: Binding<[AnnotationState<VM.PlaceType>]>
    ) -> some View {
        modifier(PlacesChangeModifier(
            viewModel: viewModel,
            previousPlaces: previousPlaces,
            annotationStates: annotationStates
        ))
    }
}
