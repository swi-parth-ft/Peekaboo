//
//  HapticManager.swift
//  Subly
//
//  Created by Parth Antala on 2025-04-08.
//


import UIKit


class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Handle impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Handle notification feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}