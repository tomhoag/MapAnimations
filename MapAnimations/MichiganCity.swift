//
//  MichiganCity.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/24/25.
//

import SwiftUI
import MapKit

struct MichiganCity: Place {

    static func == (lhs: MichiganCity, rhs: MichiganCity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: Int
    var name: String
    var coordinate: CLLocationCoordinate2D
}

enum MichiganCities: Int, CaseIterable{

    case baycity = 1
    case grandhaven
    case ecorse
    case eastpointe
    case escanaba
    case fenton
    case charlevoix
    case bloomfieldhills
    case bentonharbor

    var id: Int {
        return self.rawValue
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .baycity:
            return CLLocationCoordinate2D(latitude: 43.592846, longitude: -83.894348)
        case .grandhaven:
            return CLLocationCoordinate2D(latitude: 43.062244, longitude: -86.230759)
        case .ecorse:
            return CLLocationCoordinate2D(latitude:42.249313, longitude: -83.151329)
        case .escanaba:
            return CLLocationCoordinate2D(latitude: 45.745312, longitude: -87.070457)
        case .fenton:
            return CLLocationCoordinate2D(latitude: 42.79781, longitude: -83.70495)
        case .eastpointe:
            return CLLocationCoordinate2D(latitude:42.466595, longitude: -82.959213)
        case .charlevoix:
            return CLLocationCoordinate2D(latitude:45.317806, longitude: -85.262009)
        case .bloomfieldhills:
            return CLLocationCoordinate2D(latitude:42.583652, longitude: -83.248009)
        case .bentonharbor:
            return CLLocationCoordinate2D(latitude: 42.116463, longitude: -86.457497)
        }
    }

    var name: String {
        switch self {
        case .baycity:
            return "Bay City"
        case .grandhaven:
            return "Grand Haven"
        case .ecorse:
            return "Ecorse"
        case .eastpointe:
            return "East Pointe"
        case .fenton:
            return "Fenton"
        case .escanaba:
            return "Escanaba"
        case .charlevoix:
            return "Charlevoix"
        case .bloomfieldhills:
            return "Bloomfield Hills"
        case .bentonharbor:
            return "Benton Harbor"
        }
    }

    var asPlace: MichiganCity {
        return MichiganCity(id: self.id, name: self.name, coordinate: self.coordinate)
    }

    static func random(count: Int) -> [MichiganCity]? {
        guard count > 0 else { return nil }

        guard count < MichiganCities.allCases.count else {
            return Array(MichiganCities.allCases.map { $0.asPlace })
        }

        return Array(MichiganCities.allCases.shuffled().prefix(count)).map { $0.asPlace }
    }
}
