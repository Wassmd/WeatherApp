import Foundation
import Combine

class CurrentWeatherViewModel: ObservableObject {
  @Published var dataSource: CurrentWeatherRowViewModel?

  let city: String

  private let weatherFetcher: WeatherFetchable
  private var disposables = Set<AnyCancellable>()

  init(city: String,
       weatherFetcher: WeatherFetchable) {
    self.city = city
    self.weatherFetcher = weatherFetcher
  }

  func refresh() {
    weatherFetcher.currentWeatherForecast(forCity: city)
      .map(CurrentWeatherRowViewModel.init)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { [weak self] value in
        switch value {
          case .finished:
          break
          case .failure:
            self?.dataSource = nil
        }
      }, receiveValue: { [weak self] weather in
        self?.dataSource = weather
      })
    .store(in: &disposables)
  }
}
