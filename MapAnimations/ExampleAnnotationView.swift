//
//  ExampleAnnotationViews.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/25/25.
//

import SwiftUI
import MapKit

struct EphemeralAnnotation<ER: EphRepresentable, Content: View>: MapContent {
    let state: EphAnnotationState<ER>
    let content: () -> Content

    init(state: EphAnnotationState<ER>, @ViewBuilder content: @escaping () -> Content) {
        self.state = state
        self.content = content
    }

    @MapContentBuilder @MainActor
    var body: some MapContent {
        Annotation("", coordinate: state.place.coordinate) {
            content()
        }
    }
}

/**
 General Note: In Xcode 17 we can use the new @Observable macro for models, but since EphAnnotationState is being used with SwiftUI views and we need property observation, @ObservableObject is still the correct choice here. Changing to @Observable can cause unexpected behavior with animation states
 */

/**
 A generic ephemeral view that wraps any View content and applies the ephemeral animation effect.

 This view serves as a flexible wrapper that can take any SwiftUI view as content and apply
 the ephemeral animation effect based on the provided annotation state.

 Example usage:
 ```swift
 EphAnnotationView(annotationState: myState) {
     Text("Hello World")
 }
 ```

 - Note: In SwiftUI, the Content type is inferred from the ViewBuilder closure we pass to EphAnnotationView. When we pass Circle().frame().foregroundColor(), Swift infers Content as some View. We don't need to explicitly specify it.

 - Parameters:
   - ER: The type conforming to `EphRepresentable` protocol
   - Content: The type of view being wrapped
   - annotationState: The state object managing the ephemeral animation
   - content: A closure returning the view to be animated
 */

struct EphAnnotationView<ER: EphRepresentable, Content: View>: View {
    @ObservedObject var annotationState: EphAnnotationState<ER>
    let content: () -> Content

    init(annotationState: EphAnnotationState<ER>, @ViewBuilder content: @escaping () -> Content) {
        self.annotationState = annotationState
        self.content = content
    }

    var body: some View {
        content()
            .ephemeralEffect(annotationState: annotationState)
    }
}

/**
 A circular view with ephemeral animation effects.

 Creates an animated circle with customizable size and color. The circle animates
 in and out based on the annotation state.

 Example usage:
 ```swift
 CircleAnnotationView(
     annotationState: myState,
     diameter: 30,
     color: .red
 )
 ```
 */
struct CircleAnnotation<ER: EphRepresentable>: View {
    @ObservedObject var annotationState: EphAnnotationState<ER>
    var color: Color = .blue
    var diameter: CGFloat = 20

    var body: some View {
        EphAnnotationView(annotationState: annotationState) {
            Circle()
                .frame(width: diameter, height: diameter)
                .foregroundColor(color)
        }
    }
}

/**
 A view that displays an SF Symbol with ephemeral animation effects.

 This view creates an animated system image that changes color based on its state:
 - Red when removing
 - Blue when visible
 - Green when not visible

 Example usage:
 ```swift
 SystemImageAnnotation(
     annotationState: myState,
     systemName: "star.fill",
     font: .title
 )
 ```
 */
struct SystemImageAnnotation<ER: EphRepresentable>: View {
    @ObservedObject var annotationState: EphAnnotationState<ER>
    var systemName: String = "triangle.fill"
    var font: Font = .largeTitle

    var body: some View {
        EphAnnotationView(annotationState: annotationState) {
            let color: Color = annotationState.isRemoving ? .red : (annotationState.isVisible ? .blue : .green)

            Image(systemName: systemName)
                .foregroundColor(color)
                .font(font)
        }
    }
}
