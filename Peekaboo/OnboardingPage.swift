//
//  OnboardingPage.swift
//  Peekaboo.
//
//  Created by Parth Antala on 2025-05-03.
//


import SwiftUI
import AVKit
import UIKit
import AVFoundation

import AVKit

struct SimpleLoopingPlayer: UIViewControllerRepresentable {
    let videoName: String

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov") else {
            print("⚠️ SimpleLoopingPlayer: \(videoName).mov not found")
            return controller
        }
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = false
        player.play()
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // no-op
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    // Replace these with your own image names and copy
    private let pages: [OnboardingPage] = [
        // Video page: drawing behind the subject
        OnboardingPage(
            imageName: "v1",
            title: "Draw Behind the Subject",
            description: "Watch as you draw playful strokes behind your photo’s subject to make it come alive."
        ),
        // First image page: text behind the subject
        OnboardingPage(
            imageName: "ob3",
            title: "Place Text Behind",
            description: "Add custom text behind your subject for a layered, dynamic look."
        ),
        // Second image page: white sticker border
        OnboardingPage(
            imageName: "ob4",
            title: "Sticker-Style Border",
            description: "Wrap your subject with a crisp, white sticker-like border to make it pop."
        )
    ]
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var player = AVQueuePlayer()
    @State private var playerLooper: AVPlayerLooper?
    
    @ViewBuilder
    private func pageView(_ page: OnboardingPage, at index: Int) -> some View {
        VStack {
          
            ZStack {
                VStack {
                    Text("Peekaboo")
                        .foregroundStyle(
                            
                            LinearGradient(colors: [currentPage == 0 ? .yellow : currentPage == 1 ? .red : .mint, currentPage == 0 ? .orange : currentPage == 1 ? .red.opacity(0.6) : .cyan], startPoint: .bottom, endPoint: .top)
                            
                            
                        )
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .shadow(radius: 10)
                    Spacer()
                }
                .frame(maxHeight: UIDevice.isIpad ? 820 : 490)

                
                
                if index == 0 {
                    SimpleLoopingPlayer(videoName: page.imageName)
                       
                        .scaledToFill()
                        .frame(maxHeight: UIDevice.isIpad ? 700 : 380)
                        .cornerRadius(22)
                        .padding()
                    
                        .clipShape(Rectangle())
                        .shadow(radius: 10)
                        //.padding(.top, 35)
                } else {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: UIDevice.isIpad ? 700 : 380)
                        .cornerRadius(22)
                        .padding()
                        .clipShape(Rectangle())
                        .shadow(radius: 10)
                      //  .padding(.top, 35)
                }
                    
            }
            .frame(maxHeight: UIDevice.isIpad ? 850 : 500)
            Text(page.title)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text(page.description)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }
    
    var body: some View {
        ZStack {
            DottedBackground()
            VStack(spacing: 0) {
                
              
             
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageView(page, at: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(maxHeight: .infinity)
                //.background(.red)
                // Next / Get Started button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.system(.title2, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.clear,
                                                    currentPage == 0 ? .yellow.opacity(0.7) :
                                                        (currentPage == 1 ? .red.opacity(0.7) : .mint.opacity(0.7)),
                                                    .clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
                .shadow(color: currentPage == 0 ? .yellow : currentPage == 1 ? .red : .cyan, radius: 20)
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 30)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
