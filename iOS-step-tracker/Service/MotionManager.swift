//
//  MotionManager.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/3/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
import HealthKit
import SwiftyBeaver

class MotionManager {
    private let healthStore = HKHealthStore()
    private let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    
    func importStepsHistory(completion: @escaping (Int) -> Void) {
        let now = Date()
        let today = Calendar.current.date(byAdding: .day, value: 0, to: now)!
        
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: now)
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: nil,
                                                options: [.cumulativeSum],
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        query.initialResultsHandler = { _, results, error in
            var stepCount = 0
            guard let results = results else {
                 completion(stepCount)
                log.error("Error returned form resultHandler = \(String(describing: error?.localizedDescription))")
                return
            }
            
            results.enumerateStatistics(from: today, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    stepCount = steps
                    UserDefaults.standard.set(steps, forKey: "Step count")
                    log.debug("\(steps)")
                }
            }
            DispatchQueue.main.async {
                completion(stepCount)
            }
        }
        
        healthStore.execute(query)
    }
}
