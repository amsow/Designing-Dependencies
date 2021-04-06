//
//  WeatherClientInterface.swift
//  Designing Dependencies
//
//  Created by Amadou Diarra SOW on 31/03/2021.
//

import Foundation
import CoreLocation
import Combine

struct Location { }

struct WeatherResponse: Decodable, Equatable {
  
  let consolidatedWeather: [ConsolidatedWeather]
  
  struct ConsolidatedWeather: Decodable, Equatable {
    let applicableDate: Date
    let id: Int
    let maxTemp: Double
    let minTemp: Double
    let theTemp: Double
  }
}

/// A client for accessing weather data for locations
struct WeatherClient {
  var weather: () -> AnyPublisher<WeatherResponse, Error>
  var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}
