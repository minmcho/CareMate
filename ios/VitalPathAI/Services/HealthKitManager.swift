//
//  HealthKitManager.swift
//  HealthKit integration for sleep and activity data.
//

import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()
    var isAuthorized = false
    var lastSleepDuration: Int = 0
    var lastSleepQuality: Int = 0

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let active = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(active)
        }
        if let hr = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(hr)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }()

    func requestAuthorization() async {
        guard Self.isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func fetchLastNightSleep() async -> (durationMin: Int, quality: Int) {
        guard Self.isAvailable, isAuthorized else { return (0, 0) }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, 0)
        }

        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: now,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 20,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: (0, 0))
                    return
                }
                var totalSleep: TimeInterval = 0
                var deepSleep: TimeInterval = 0
                for sample in samples {
                    let dur = sample.endDate.timeIntervalSince(sample.startDate)
                    if sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        deepSleep += dur
                        totalSleep += dur
                    } else if sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                        totalSleep += dur
                    }
                }
                let durationMin = Int(totalSleep / 60.0)
                var quality = 0
                if durationMin >= 420 && durationMin <= 540 { quality += 40 }
                else if durationMin >= 300 { quality += 25 }
                if deepSleep > 0 && totalSleep > 0 {
                    let deepPct = deepSleep / totalSleep
                    quality += deepPct >= 0.15 ? 30 : 15
                }
                quality += min(30, durationMin / 15)
                quality = min(quality, 100)
                cont.resume(returning: (durationMin, quality))
            }
            store.execute(query)
        }
    }

    func fetchSteps(for date: Date) async -> Int {
        guard Self.isAvailable, isAuthorized else { return 0 }
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                cont.resume(returning: steps)
            }
            store.execute(query)
        }
    }
}
