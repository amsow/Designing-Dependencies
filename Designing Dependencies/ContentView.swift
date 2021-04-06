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
import WeatherClient

let dateOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()

class AppViewModel: ObservableObject {
  @Published var isConnected = true
  @Published var weatherResults = [WeatherResponse.ConsolidatedWeather]()
  
  var weatherRequestCancellable: AnyCancellable?
  let weatherClient: WeatherClient
  
  init(isConnected: Bool = true, weatherClient: WeatherClient) {
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
}



