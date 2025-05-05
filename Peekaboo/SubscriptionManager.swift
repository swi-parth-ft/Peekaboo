//
//  SubscriptionManager.swift
//  AR spotit
//
//  Created by Parth Antala on 2025-03-21.
//
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isPremium: Bool = false
    private init() { }
}

import Foundation
import RevenueCat
import Drops
import SwiftUI




class SubscriptionManager: ObservableObject {
 
    @Published var isPremium = false
    @Published var subscriptionStatus = "Inactive"
  
    @Published var trialUsed: Bool = false
    @Published var prodId = ""
    @Published var isPurchasing: Bool = false
    @Published var isPurchaseSucceeded: Bool = false
    @Published var isChecked = false
    init() {
        
        // Load persisted premium state
        self.isPremium = AppState.shared.isPremium
        
       
            checkRevenueCatStatus()
        
      
    }

    func checkRevenueCatStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let customerInfo = customerInfo, customerInfo.entitlements["Plus"]?.isActive == true {
                print("User has an active premium subscription")
                self.isPremium = true
                AppState.shared.isPremium = true
                self.isChecked = true

            } else {
                
                print("User does not have a premium subscription")
                self.isPremium = false
                AppState.shared.isPremium = false
                self.isChecked = true

            }
            // Persist premium flag
        //    self.sharedDefaults.set(self.isPremium, forKey: "isPremium")
        }
    }

    func purchasePremium(package: Package) {
        Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
            if let error = error {
                print("Purchase failed: \(error.localizedDescription)")
                Drops.show("Please Try Again!")
                HapticManager.shared.notification(type: .error)

                self.isPurchasing = false
                AppState.shared.isPremium = false
                return
            } else {
                self.isPurchasing = false
                
            }
            if let customerInfo = customerInfo, customerInfo.entitlements["Plus"]?.isActive == true {
                print("✅ Premium subscription activated!")
                
                Drops.show("Premium Unlocked!")
                HapticManager.shared.notification(type: .success)
                AppState.shared.isPremium = true
                self.isPurchaseSucceeded = true
                self.isPremium = true
             
              //  self.updateSubscriptionStatus(status: "active")
           
              
            }
        }
    }

    func restorePurchases(completion: @escaping (Bool) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                print("Restore failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            if let customerInfo = customerInfo, customerInfo.entitlements["Plus"]?.isActive == true {
                Drops.show("Purchases restored successfully")
                HapticManager.shared.notification(type: .success)
               
                self.isPremium = true
                AppState.shared.isPremium = true
                self.isPurchaseSucceeded = true
                //  AppState.shared.isPremium = true
                completion(true)
            } else {
                Drops.show("No active subscription found")
                HapticManager.shared.notification(type: .error)
                self.isPremium = false  // reset premium when no subscription
                AppState.shared.isPremium = false

                completion(false)
            }
        }
    }

 
    
}
