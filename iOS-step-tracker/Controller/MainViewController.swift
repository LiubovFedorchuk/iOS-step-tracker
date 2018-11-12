//
//  MainViewController.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/3/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import UIKit
import CoreMotion

class MainViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var stepsCountLabel: UILabel!
    @IBOutlet weak var walkerImageView: UIImageView!
    
    private let alertSetUp = AlertSetUp()
    private let pedometer = CMPedometer()
    private let today = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addImageToUIImageView()
        self.checkAuthorizationStatus()
        self.dateLabel.text = getCurrentDateInReadableFormat(self.today)

        if(UserDefaults.standard.bool(forKey: "success") == false) {
            self.authorizeHealthKit()
        } else {
            startUpdating(startDate: today)
        }
    }
    
    private func checkAuthorizationStatus() {
        switch CMMotionActivityManager.authorizationStatus() {
        case CMAuthorizationStatus.denied:
            self.alertSetUp.showAlert(alertTitle: "Authorization failed", alertMessage: "Authorization failed due to access denied.")
            log.error("Access denied.")
            stepsCountLabel.text = "Not available"
        default:break
        }
    }
    
    private func startUpdating(startDate: Date) {
        if CMPedometer.isStepCountingAvailable() {
            startCountingStepsFromMidnight(startDate: startDate)
        } else {
            self.alertSetUp.showAlert(alertTitle: "Unexpected error", alertMessage: "Step counting is not available.")
            log.error("Step counting is not available.")
            stepsCountLabel.text = "Not available"
        }
    }

    private func startCountingStepsFromMidnight(startDate: Date)  {
        
        pedometer.startUpdates(from: self.getMidnightOfToday(self.today)) { data, error in
            guard let activityData = data, error == nil else {
                self.alertSetUp.showAlert(alertTitle: "Data obtaining error.", alertMessage: "There was an error getting the data by reason of: \(error!.localizedDescription)")
                log.error("Data obtaining error. Reason: \(error!.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.stepsCountLabel.text = activityData.numberOfSteps.stringValue
            }
            let stepCount = activityData.numberOfSteps.doubleValue
            if(startDate == self.getEndOfDay(self.today)){
                self.saveData(currentStepCount: stepCount)
                self.getCurrentStepCountForSavingToFirebase()
            }
        }
    }

    private func authorizeHealthKit() {
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
            self.startUpdating(startDate: self.today)
        }
    }
    
    private func saveData(currentStepCount: Double) {
        let healthKitManager = HealthKitManager()
        healthKitManager.saveStepCountToHealthKitStore(stepCountIndex: currentStepCount, date: today)
    }

    private func getCurrentStepCountForSavingToFirebase(){
        let healthKitManager = HealthKitManager()
        healthKitManager.getTodaysStepCount(completion: {steps, date, error in
            log.debug("Success. Step count: \(steps)")
        })
    }
    
    private func addImageToUIImageView() {
        let walkerImage: UIImage = UIImage(named: "walker")!
        walkerImageView.image = walkerImage
    }
    
    func getEndOfDay(_ now: Date) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: now)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = Calendar.current.date(byAdding: components, to: startOfDay)!
        return endOfDay
    }
    
    func getMidnightOfToday(_ now: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = NSTimeZone.local
        let midnightOfToday = calendar.startOfDay(for: now)
        return midnightOfToday
    }
    
    private func getCurrentDateInReadableFormat(_ now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US")
        let date = dateFormatter.string(from: now)
        return date
    }
}

