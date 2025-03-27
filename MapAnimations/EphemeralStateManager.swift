//
//  EphemeralStateManager.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/27/25.
//


import SwiftUI
import MapKit
import MichiganCities

@MainActor @Observable
class EphStateManager<ER: EphRepresentable>: ObservableObject {
    var previousPlaces: [ER]?
    var annotationStates: [EphAnnotationState<ER>] = []
}
