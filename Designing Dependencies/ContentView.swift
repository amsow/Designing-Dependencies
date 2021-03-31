//
//  ContentView.swift
//  Designing Dependencies
//
//  Created by Amadou Diarra SOW on 31/03/2021.
//

import SwiftUI
import Combine
import Foundation
import CoreLocation

struct Location { }

protocol WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error>
  func searchLocations(coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}

//struct WeatherClient: WeatherClientProtocol {
//  func searchLocations(coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Location], Error> {
//
//  }
//
//  func weather() -> AnyPublisher<WeatherResponse, Error> {
//    return URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/2459115")!)
//      .map { data, _ in data }
//      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
//      .receive(on: DispatchQueue.main)
//      .eraseToAnyPublisher()
//  }
//}

struct WeatherClient {
  var weather: () -> AnyPublisher<WeatherResponse, Error>
  var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}

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
  
  static let empty = Self(
    weather: {
      Just(WeatherResponse(consolidatedWeather: []))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    },
    searchLocations: { _ in
      Just([])
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    })
  
  static let happyPath = Self(
    weather: {
      Just(WeatherResponse(
            consolidatedWeather: [
              .init(applicableDate: Date(), id: 1, maxTemp: 30, minTemp: 10, theTemp: 20),
              .init(applicableDate: Date().addingTimeInterval(86400), id: 2, maxTemp: -10, minTemp: -30, theTemp: -20)
            ]))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    },
    searchLocations: { _ in
      Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    })
  
  static let failed = Self(
    weather: {
      Fail(error: NSError(domain: "any-domain", code: 2, userInfo: nil))
        .eraseToAnyPublisher()
    },
    searchLocations: { _ in
      Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    })
}

class AppViewModel: ObservableObject {
  @Published var isConnected = true
  @Published var weatherResults = [WeatherResponse.ConsolidatedWeather]()
  
  var weatherRequestCancellable: AnyCancellable?
  let weatherClient: WeatherClient
  
  init(isConnected: Bool = true, weatherClient: WeatherClient = .live) {
    self.isConnected = isConnected
    self.weatherClient = weatherClient
    self.weatherRequestCancellable = weatherClient.weather()
      .sink(receiveCompletion: { _ in },
            receiveValue: { [weak self] response in
                self?.weatherResults = response.consolidatedWeather })
    
  }
}

struct ContentView: View {
  
  @ObservedObject var viewModel: AppViewModel
  
  var body: some View {
    
    NavigationView {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .bottomTrailing) {
          List {
            ForEach(self.viewModel.weatherResults, id: \.id) { weather in
              VStack(alignment: .leading) {
                Text(dateOfWeekFormatter.string(from: weather.applicableDate).capitalized)
                  .font(.title)
                Text("Current temp: \(weather.theTemp, specifier: "%.1f")°C")
                Text("Max temp: \(weather.maxTemp, specifier: "%.1f")°C")
                Text("Min temp: \(weather.minTemp, specifier: "%.1f")°C")
              }
            }
          }
          
          Button(action: { }) {
            Image(systemName: "location.fill")
              .foregroundColor(.white)
              .frame(width: 60, height: 50)
          }
          .background(Color.black)
          .clipShape(Circle())
          .padding()
        }
        
        if !self.viewModel.isConnected {
          HStack {
            Image(systemName: "exclamationmark.octagon.fill")
            Text("Not connected to Internet")
          }
          .foregroundColor(.white)
          .padding()
          .background(Color.red)
        }
      }
      
      .navigationBarTitle("Weather")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(viewModel: AppViewModel(weatherClient: .live))
  }
//
//  AppViewModel(
//                  weatherClient: MockWeatherClient(
//                    _weather: {
//                      Just(WeatherResponse(consolidatedWeather: []))
//                        .setFailureType(to: Error.self)
//                        .eraseToAnyPublisher()
//                    } ,
//                    _searchLocations: { _ in
//                      Just([])
//                        .setFailureType(to: Error.self)
//                        .eraseToAnyPublisher()
//                    }))
}



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

private let weatherJsonDecoder: JSONDecoder = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  $0.dateDecodingStrategy = .formatted(formatter)
  $0.keyDecodingStrategy = .convertFromSnakeCase
  return $0
}(JSONDecoder())


let dateOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
