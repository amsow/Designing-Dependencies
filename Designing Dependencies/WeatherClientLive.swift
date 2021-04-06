//
//  WeatherClientLive.swift
//  Designing Dependencies
//
//  Created by Amadou Diarra SOW on 06/04/2021.
//

import Combine
import Foundation

extension WeatherClient {
  static let live = Self(
    weather: {
      return URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/2459115")!)
        .map { data, _ in data }
        .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    },
    searchLocations: { _ in
      Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    })
}

private let weatherJsonDecoder: JSONDecoder = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  $0.dateDecodingStrategy = .formatted(formatter)
  $0.keyDecodingStrategy = .convertFromSnakeCase
  return $0
}(JSONDecoder())

