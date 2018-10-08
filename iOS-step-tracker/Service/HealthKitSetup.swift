//
//  HealthKitSetup.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/4/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitSetup {
    
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }
        
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }
        
        let healthKitTypesToRead: Set<HKObjectType> = [stepCount]
        HKHealthStore().requestAuthorization(toShare: nil,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
}
