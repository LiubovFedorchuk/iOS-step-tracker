//
//  DBManager.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/9/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
import Firebase

class DBManager {
    
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
