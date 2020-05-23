import SwiftUI
import Combine
import Foundation

class WeeklyWeatherViewModel: ObservableObject {

  private let weatherFetcher: WeatherFetchable
  private let scheduler: DispatchQueue
  private var disposables = Set<AnyCancellable>()

  @Published var city: String = ""
  @Published var dataSource: [DailyWeatherRowViewModel] = []

  init(weatherFetcher: WeatherFetchable = WeatherFetcher(),
       scheduler: DispatchQueue = DispatchQueue(label: "WeatherViewModel")) {
    self.weatherFetcher = weatherFetcher
    self.scheduler = scheduler

    setupObservable()
  }

  private func setupObservable() {
    $city
    .dropFirst(1)
    .debounce(for: .seconds(0.5), scheduler: scheduler)
    .sink(receiveValue: fetchWeather(forCity:))
    .store(in: &disposables)
  }

  func fetchWeather(forCity city: String) {
    print("Wasim isMainThread:\(Thread.isMainThread)")
    weatherFetcher.weeklyWeatherForecast(forCity: city)
      .map { response in
        response.list.map(DailyWeatherRowViewModel.init)
    }
    .map(Array.removeDuplicates)
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { [weak self] value in
      guard let self = self else { return }

      switch value {
        case .finished:
          break
        case .failure:
          self.dataSource = []

      }
      }, receiveValue: { [weak self] forecast in
        guard let self = self else { return }
        self.dataSource = forecast
    })
      .store(in: &disposables)
  }
}

extension WeeklyWeatherViewModel {
  var currentWeatherView: some View {
    return WeeklyWeatherBuilder.makeCurrentWeatherView(withCity: city, weatherFetcher: weatherFetcher)
  }
}
