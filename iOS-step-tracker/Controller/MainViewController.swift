//
//  MainViewController.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/3/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var stepsCountLabel: UILabel!
    @IBOutlet weak var walkerImageView: UIImageView!
    let alertSetUp = AlertSetUp()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addImageToUIImageView()
        self.dateLabel.text = getCurrentDateInReadableFormat()
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
    
    func getCurrentDateInReadableFormat() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US")
        let date = dateFormatter.string(from: now)
        return date
    }
    
    func getStepCount(){
        let healthKitManager = HealthKitManager()
        healthKitManager.getCurrentStepCount(completion: { [weak self] steps, date  in
            self?.stepsCountLabel.text = "\(steps)"
        })
    }
    
    func addImageToUIImageView() {
        let walkerImage: UIImage = UIImage(named: "walker")!
        walkerImageView.image = walkerImage
    }
}

