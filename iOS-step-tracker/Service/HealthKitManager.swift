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
    
    func getTodaysStepCount(completion: @escaping (_ steps: Int, _ date: String, _ error: Error?) -> Void) {
        var stepCount = 0
        let now = Date()
        let today = Calendar.current.date(byAdding: .day, value: 0, to: now)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let dateToShow = dateFormatter.string(from: today)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: stepsQuantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let result = results!.first as? HKQuantitySample else {
                log.error("Error. Result: \(error!.localizedDescription)")
                completion(stepCount, dateToShow, error)
                return
            }
            stepCount = Int(result.quantity.doubleValue(for: HKUnit.count()))
            log.debug("Success. Step count: \(stepCount)")
            DispatchQueue.main.async {
                completion(stepCount, dateToShow, nil)
            }
        }
        healthStore.execute(query)
    }

    func saveStepCountToHealthKitStore(stepCountIndex: Double, date: Date) {
        
        guard let stepCountIndexType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            fatalError("Step count index type is no longer available in HealthKit.")
        }
        let stepQuantity = HKQuantity(unit: HKUnit.count(),
                                          doubleValue: stepCountIndex)
        let stepCountIndexData = HKQuantitySample(type: stepCountIndexType,
                                                   quantity: stepQuantity,
                                                   start: date,
                                                   end: date)
        HKHealthStore().save(stepCountIndexData) { (success, error) in
            
            if let error = error {
                log.error("Error saving step count data: \(error.localizedDescription)")
            } else {
                log.debug("Data was saved successfully.")
            }
        }
    }
    
    func enableBackgroundDelivery() {
        let query = HKObserverQuery(sampleType: stepsQuantityType, predicate: nil) { [weak self] (query, completionHandler, error) in
            if let error = error {
                log.error("Observer query failed = \(error.localizedDescription)")
                return
            }
            
            self?.getTodaysStepCount (completion: { steps, date, error  in
                let dbManager = DBManager()
                dbManager.pasteDataToFirebaseDB(date: date, stepCount: steps) {
                    completionHandler()
                }
            })
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepsQuantityType, frequency: .immediate) { (success, error) in
            log.debug("Background delivery of steps. Success = \(success)")
            
            if let error = error {
                log.error("Background delivery of steps failed = \(error.localizedDescription)")
            }
        }
    }
}
