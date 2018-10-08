//
//  ViewController.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/3/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var stepsCountLabel: UILabel!
    let alertSetUp = AlertSetUp()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(UserDefaults.standard.bool(forKey: "success") == false) {
            self.authorizeHealthKitWithStepCount()
        } else {
            self.getStepCount()
        }
    }

    private func authorizeHealthKitWithStepCount() {
        let healthKitSetup = HealthKitSetup()
        
        healthKitSetup.authorizeHealthKit { (authorized, error) in
            guard authorized else {
                if let error = error {
                    self.alertSetUp.showAlert(alertTitle: "HealthKit authorization failed", alertMessage: "HealthKit authorization failed by reason of: \(error.localizedDescription)")
                    log.error("HealthKit authorization failed. Reason: \(error.localizedDescription)")
                    UserDefaults.standard.set(false, forKey: "success")
                } else {
                    self.alertSetUp.showAlert(alertTitle: "Unexpected error", alertMessage: "HealthKit authorization failed.")
                    log.error("HealthKit authorization failed.")
                    UserDefaults.standard.set(false, forKey: "success")
                }
                
                return
            }
            UserDefaults.standard.set(true, forKey: "success")
            log.debug("HealthKit successfully authorized.")
            self.getStepCount()
        }
    }
    
    func getStepCount() {
        let motionManager = MotionManager()
        motionManager.importStepsHistory(completion: { [weak self] steps in
            self?.stepsCountLabel.text = "\(steps)"
        })
    }
}

