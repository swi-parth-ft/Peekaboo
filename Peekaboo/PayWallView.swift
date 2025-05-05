//
//  PaywallView.swift
//  AR spotit
//
//  Created by Parth Antala on 2025-03-21.
//

import SwiftUI
import RevenueCat

struct PremiumFeature: Identifiable {
    let id = UUID()
    let title: String
    let sfSymbol: String
    let color: Color
}

let premiumFeatures = [
    PremiumFeature(title: "Full Unit Converter", sfSymbol: "ruler.fill", color: .blue),
    PremiumFeature(title: "Up to 6 Decimal Places", sfSymbol: "123.rectangle.fill", color: .green),
    PremiumFeature(title: "Premium Keyboard Themes", sfSymbol: "paintpalette.fill", color: .pink),
    PremiumFeature(title: "Remove Keycal Branding", sfSymbol: "checkmark.seal.fill", color: .orange)
]


struct PayWallView: View {
    @StateObject private var manager = SubscriptionManager()
    @State private var offering: Offering?
    @State private var purchaseStatus: String = "Loading..."
    @State private var isLoading = true
    @State private var selectedPackage: Package? = nil
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss  // Enables the "Close" button to dismiss
    
    var saving = false
    var OnsaveWithWatermark: () -> Void = { }
    // Helper to get display title for package type
    // Helper to get display title for package type
    private func title(for package: Package) -> String {
        switch package.packageType {
        case .lifetime:
            return "Lifetime Access"
        case .annual:
            return "Annual Subscription"
        case .monthly:
            return "Monthly Subscription"
        default:
            return String(describing: package.packageType).capitalized
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
               DottedBackground()
                   // .ignoresSafeArea()
                ZStack {
                    VStack {
                        LinearGradient(colors: [.yellow.opacity(0.7), .orange.opacity(0.5), .clear, .clear, .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 300)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    VStack {
                        Spacer()
                        
                        VStack {
                            
                            // Spacer()
                            // Header
                            VStack {
                                Text("Peekaboo+")
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 2)
                                
                                
                                Text("No Watermarks. Just Creativity.")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                            }
                            .padding(.bottom)
                            
                            
                            
                            
                            //   Offerings
                            if isLoading {
                                ProgressView("Loading...")
                            } else if let offering = offering {
                                VStack {
                                    ForEach(offering.availablePackages, id: \.identifier) { package in
                                        Button(action: {
                                            selectedPackage = package
                                        }) {
                                            ZStack(alignment: .topTrailing) {
                                                HStack {
                                                    Text("\(title(for: package))")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(package.localizedPriceString)")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(Color.primary.opacity(0.2))
                                                .cornerRadius(10)
                                                .overlay(
                                                    selectedPackage?.identifier == package.identifier
                                                    ? RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 2)
                                                    : nil
                                                )
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("No subscriptions available")
                                    .foregroundColor(.red)
                            }
                            
                            // Purchase Action Button
                            Button(action: {
                                if let selected = selectedPackage {
                                    manager.purchasePremium(package: selected)
                                    manager.isPurchasing = true
                                }
                            }) {
                                
                                //       New subscription or trial
                                if let selected = selectedPackage {
                                    Text("Unlock Peekaboo+")
                                        .font(.system(.title2, design: .rounded))
                                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                                        .bold()
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 55)
                                        .background(Color.primary.opacity(1))
                                        .cornerRadius(10)
                                    
                                }
                                
                            }
                            
                            if saving {
                                Button {
                                    OnsaveWithWatermark()
                                } label: {
                                    Text("Save with Watermark")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        .bold()
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 55)
                                    // .background(Color.primary.opacity(1))
                                        .cornerRadius(10)
                                }
                            }
                            
                            
                            Button("Restore Purchases") {
                                manager.restorePurchases { success in
                                    if success {
                                        dismiss()
                                        purchaseStatus = "Purchases restored!"
                                        
                                    } else {
                                        purchaseStatus = "Failed to restore purchases."
                                    }
                                }
                            }
                            
                            
                            // Subscription/Auto-Renew Disclaimer
                            Text("Renews automatically unless canceled. Manage in Apple ID settings.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                            
                            
                            
                            // Terms and Privacy Links
                            HStack {
                                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                Spacer()
                                Link("Privacy Policy", destination: URL(string: "https://itshere.space/PeekabooPrivacy.html")!)
                            }
                            .font(.footnote)
                            .padding(.horizontal, 40)
                        }
                        .padding()
                        
                        .onAppear {
                            // Only load offerings once
                            guard offering == nil else { return }
                            isLoading = true
                            Purchases.shared.getOfferings { offerings, error in
                                if let error = error {
                                    purchaseStatus = "Error loading subscriptions: \(error.localizedDescription)"
                                    isLoading = false
                                    return
                                }
                                self.offering = offerings?.current
                                if let currentOffering = self.offering {
                                    self.selectedPackage = currentOffering.availablePackages.first
                                }
                                isLoading = false
                            }
                        }
                    }
                }
              //   Purchasing overlay
                if manager.isPurchasing {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                   
                    VStack {
                        ProgressView {
                            Text("Purchase in progress...")
                                .font(.system(.headline, design: .rounded))
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: manager.isPurchaseSucceeded) {
                if manager.isPurchaseSucceeded {
                    dismiss()
                }
            }
            // Optional Close Button in the navigation bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button {
                      dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 2)

                    }
                }
            }
        }
    }
}

#Preview {
    PayWallView()
      //  .environmentObject(SubscriptionManager())
}
