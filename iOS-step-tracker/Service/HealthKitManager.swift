//
//  HealthKitManager.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/3/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class HealthKitManager {
    static let sharedHealthKitManager = HealthKitManager()
    private let healthStore = HKHealthStore()
    private let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    
    func getCurrentStepCount(completion: @escaping (Int, String) -> Void) {
        let now = Date()
        let today = Calendar.current.date(byAdding: .day, value: 0, to: now)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let dateToShow = dateFormatter.string(from: today)
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
                 completion(stepCount, dateToShow)
                log.error("Error returned form resultHandler = \(String(describing: error?.localizedDescription))")
                return
            }
            
            results.enumerateStatistics(from: today, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    stepCount = steps
                    UserDefaults.standard.set(steps, forKey: "Step count")
                    log.debug("\(steps) " + "\(today)")
                }
            }
            DispatchQueue.main.async {
                completion(stepCount, dateToShow)
            }
        }
        
        healthStore.execute(query)
    }
    
    func enableBackgroundDelivery() {
        let query = HKObserverQuery(sampleType: stepsQuantityType, predicate: nil) { [weak self] (query, completionHandler, error) in
            if let error = error {
                log.error("Observer query failed = \(error.localizedDescription)")
                return
            }
            
            self?.getCurrentStepCount(completion: { steps, date in
                let dbManager = DBManager()
                dbManager.pasteDataToFirebaseDB(date: date, stepCount: steps) {
                    completionHandler()
                }
            })
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepsQuantityType, frequency: .daily) { (success, error) in
            log.debug("Background delivery of steps. Success = \(success)")
            
            if let error = error {
                log.error("Background delivery of steps failed = \(error.localizedDescription)")
            }
        }
    }
 
    
    func pasteDataToFirebaseDB(date: String, stepCount: Int, withCompletion completion: (() -> Void)? = nil) {
        var databaseReference: DatabaseReference!
        
        databaseReference = Database.database().reference().child("data")
        let key = databaseReference.childByAutoId().key!
        let newActivity = ["id" : key,
                           "step_count" : stepCount,
                           "date" : date] as [String : Any]
        databaseReference.child(key).setValue(newActivity){ (error, _) in
            if let completion = completion {
                completion()
            }
        }
    }
}
