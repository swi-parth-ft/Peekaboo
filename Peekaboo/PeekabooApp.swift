//
//  PeekabooApp.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-04-27.
//

import SwiftUI
import RevenueCat
import StoreKit


@main
struct PeekabooApp: App {
    @State private var isShowingWall = false
    @StateObject private var appState = AppState.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("count") private var count = 0
    
    init() {
        Purchases.configure(withAPIKey: "appl_ItfTAEMBLtaadazULgJdpbFRjaq")
        Task {
            try? await Purchases.shared.syncPurchases()
            print("Purchases synced successfully")
        }
        // Optional: listen for entitlement changes to update isPremium
        Purchases.shared.getCustomerInfo { info, error in
            guard let info = info else { return }
            let isActive = info.entitlements["Plus"]?.isActive == true
            AppState.shared.isPremium = isActive
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
            } else {
                //   ContentView()
                ContentView()
                    .onAppear {
                        
//                        if count == 2 {
//                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                                SKStoreReviewController.requestReview(in: scene)
//                            } else {
//                                SKStoreReviewController.requestReview()
//                            }
//                        }
                        // After 2 seconds, present paywall if not premium
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            //                        let isPremium = sharedDefaults.bool(forKey: "isPremium")
                            if !appState.isPremium {
                                isShowingWall = true
                            }
                        }
                    }
                    .sheet(isPresented: $isShowingWall) {
                        PayWallView()
                            .if(!UIDevice.isIpad) { view in
                                view.presentationDetents([.fraction(0.7)])
                            }
                        
                    }
            }
        }
    }
}
