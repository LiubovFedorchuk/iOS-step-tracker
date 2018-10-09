//
//  DAL.swift
//  iOS-step-tracker
//
//  Created by Liubov Fedorchuk on 10/9/18.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
//import FirebaseDatabase
import Firebase

class DAL {
    
    func tmp() {
        var databaseReference: DatabaseReference!
        var databaseHandle: DatabaseHandle!
        databaseReference = Database.database().reference()
        //Writing data
        let newActivity = ["date" : "2018-10-09",
                           "step_count" :  1234,
                           "user_name" : "Karoline Jones"] as [String : Any]
//        databaseReference.child("data").setValue(newActivity)
        //Reading data
        databaseHandle = databaseReference.child("data/user_name").observe(.childAdded, with: {(data) in
            let userName = (data.value as? String)!
            print("\(userName)")
        })
    }
}
