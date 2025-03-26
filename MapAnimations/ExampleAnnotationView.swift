//
//  ExampleAnnotationViews.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/25/25.
//

import SwiftUI


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

 - Parameters:
   - P: The type conforming to `EphRepresentable` protocol
   - Content: The type of view being wrapped
   - annotationState: The state object managing the ephemeral animation
   - content: A closure returning the view to be animated
 */
struct EphAnnotationView<P: EphRepresentable, Content: View>: View {
    @ObservedObject var annotationState: EphAnnotationState<P>
    let content: Content

    init(annotationState: EphAnnotationState<P>, @ViewBuilder content: () -> Content) {
        self.annotationState = annotationState
        self.content = content()
    }

    var body: some View {
        content
            .ephemeralEffect(annotationState: annotationState)
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
 EphSystemImageAnnotationView(
     annotationState: myState,
     systemName: "star.fill",
     font: .title
 )
 ```

 - Parameters:
   - P: The type conforming to `EphRepresentable` protocol
   - annotationState: The state object managing the ephemeral animation
   - systemName: The name of the SF Symbol to display (default: ".triangle.fill")
   - font: The font size for the system image (default: .largeTitle)
 */
struct EphSystemImageAnnotationView<P: EphRepresentable>: View {
    @ObservedObject var annotationState: EphAnnotationState<P>
    var systemName: String = "triangle.fill"
    var font: Font = .largeTitle

    var body: some View {
        let color: Color = annotationState.isRemoving ? .red : (annotationState.isVisible ? .blue : .green)

        Image(systemName: systemName)
            .foregroundColor(color)
            .font(font)
            .ephemeralEffect(
                annotationState: annotationState,
                addingAnimation: .easeInOut(duration: 2.0),
                removingAnimation: .easeInOut(duration: 2.0)
            )
    }
}

/**
 A circular view with ephemeral animation effects.

 Creates an animated circle with customizable size and color. The circle animates
 in and out based on the annotation state.

 Example usage:
 ```swift
 EphCircleAnnotationView(
     annotationState: myState,
     diameter: 30,
     color: .red
 )
 ```

 - Parameters:
   - P: The type conforming to `EphRepresentable` protocol
   - annotationState: The state object managing the ephemeral animation
   - diameter: The width and height of the circle (default: 25)
   - color: The color of the circle (default: .yellow)
 */
struct EphCircleAnnotationView<P: EphRepresentable>: View {
    @ObservedObject var annotationState: EphAnnotationState<P>
    var diameter: CGFloat = 25
    var color: Color = .yellow

    var body: some View {
        Circle()
            .frame(width: diameter, height: diameter)
            .foregroundColor(color)
            .ephemeralEffect(annotationState: annotationState)
    }
}
