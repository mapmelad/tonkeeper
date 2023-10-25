//
//  RateWidgetTimelineProvider.swift
//  TonkeeperWidgetExtension
//
//  Created by Grigory on 25.9.23..
//

import WidgetKit
import WalletCore
import TKCore
import TKChart

struct RateWidgetTimelineProvider: IntentTimelineProvider {
  func placeholder(in context: Context) -> RateWidgetEntry {
    RateWidgetEntry(
      date: Date(),
      period: "W",
      information: .init(date: "2018 Wed, 31 Oct",
                         amount: "$2.3381",
                         percentDiff: "+63.08%",
                         fiatDiff: "$0.90",
                         diffDirection: .up),
      chartData: .init(data: RateWidgetChartMock.data,
                       minimumValue: "$1.47",
                       maximumValue: "$2.57")
    )
  }
  
  func getSnapshot(for configuration: RateWidgetIntent,
                   in context: Context,
                   completion: @escaping (RateWidgetEntry) -> Void) {
    let entry = RateWidgetEntry(
      date: Date(),
      period: "W",
      information: .init(date: "2018 Wed, 31 Oct",
                         amount: "$2.3381",
                         percentDiff: "+63.08%",
                         fiatDiff: "$0.90",
                         diffDirection: .up),
      chartData: .init(data: RateWidgetChartMock.data,
                       minimumValue: "$1.47",
                       maximumValue: "$2.57")
    )
    completion(entry)
  }
  
  func getTimeline(
    for configuration: RateWidgetIntent,
    in context: Context,
    completion: @escaping (Timeline<RateWidgetEntry>) -> Void) {
      let currency: Currency
      if let configurationCurrencyIdentifier = configuration.currency?.identifier,
         let configurationCurrency = Currency(rawValue: configurationCurrencyIdentifier) {
        currency = configurationCurrency
      } else {
        currency = .USD
      }
      let coreAssembly = CoreAssembly()
      let walletCoreContainer = WalletCore.Assembly(dependencies: Dependencies(
        cacheURL: coreAssembly.cacheURL,
        sharedCacheURL: coreAssembly.sharedCacheURL,
        sharedKeychainGroup: coreAssembly.keychainAccessGroupIdentifier)
      )
      let chartController = walletCoreContainer.chartController()
      Task {
        let period: WalletCore.Period
        let mode: TKLineChartView.Mode
        switch configuration.period {
        case .day:
          period = .day
          mode = .linear
        case .halfYear:
          period = .halfYear
          mode = .linear
        case .hour:
          period = .hour
          mode = .stepped
        case .month:
          period = .month
          mode = .linear
        case .unknown:
          period = .week
          mode = .linear
        case .week:
          period = .week
          mode = .linear
        case .year:
          period = .year
          mode = .linear
        }
        let data = try await chartController.getChartData(period: period, currency: currency)
        let information = await chartController.getInformation(at: data.count-1, period: period, currency: currency)
        let maximumValue = await chartController.getMaximumValue(currency: currency)
        let minimumValue = await chartController.getMinimumValue(currency: currency)
        let entryInformation = RateWidgetEntry.Information(chartPointInformationViewModel: information)
        let entry = RateWidgetEntry(date: Date(),
                                    period: period.title,
                                    information: entryInformation,
                                    chartData: .init(data: .init(coordinates: data, mode: mode),
                                                     minimumValue: minimumValue,
                                                     maximumValue: maximumValue))
        let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 30), to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
      }
    }
}

extension WalletCore.Coordinate: TKChart.Coordinate {}
