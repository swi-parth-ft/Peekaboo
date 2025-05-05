//
//  SettingsView.swift
//  Noted.
//
//  Created by Parth Antala on 2025-03-31.
//

import SwiftUI
import StoreKit
//import Drops
//import RevenueCat


struct SettingsView: View {
//    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var sub: SubscriptionManager
//
//    @AppStorage("sortOption") private var sortOption: ContentView.SortOption = .date
    @AppStorage("isAscending") private var isAscending: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @State private var isShowingSiriGuide: Bool = false
    @State private var isShowingExamples = false
    @State private var isLogginout = false
    @State private var isDeletingAccount: Bool = false
    @State private var isShowingPlans = false
    @State private var isManagingSubscriptions = false
    @StateObject private var appState = AppState.shared

    var body: some View {
        NavigationStack {
            Form {
       
                Section {
                    HStack {
                        Text("Current Plan")
                        Spacer()
                        
                        Text(appState.isPremium ? "Plus" : "Free")
                            .foregroundColor(appState.isPremium ? .green : .red)
                    }
                    
                    if !AppState.shared.isPremium {
                        HStack {
                            Button {
                                isShowingPlans = true
                            } label: {
                                Text("Buy Premium")
                                    .foregroundStyle(.blue)
                            }
                            

                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    
                }
                Section {
                    HStack {
                        Button("Leave a Review") {
                            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                if #available(iOS 18.0, *) {
                                    AppStore.requestReview(in: scene)
                                } else {
                                    SKStoreReviewController.requestReview(in: scene)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "pencil.and.scribble")
                    }
                    .foregroundStyle(.blue)

                }
                
                
                Section {
                 
                    HStack {
                        Link("Privacy Policy", destination: URL(string: "https://itshere.space/NotedPrivacy.html")!)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Spacer()
                        Image(systemName: "shield.lefthalf.filled")
                    }
                    
                    HStack {
                        Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Spacer()
                        Image(systemName: "doc.append.fill")
                    }
                    
                    Text("© 2025 Parth Antala. All rights reserved.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .font(.system(.headline, design: .rounded))
            .sheet(isPresented: $isShowingPlans) {
                PayWallView()
                    .if(!UIDevice.isIpad) { view in
                        view.presentationDetents([.medium])
                    }
                    
            }


            
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
