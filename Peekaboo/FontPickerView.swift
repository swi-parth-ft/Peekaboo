//
//  FontPickerView.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//

import SwiftUI
import UIKit

/// A sheet listing all fonts, previewing “peekaboo” in each style
struct FontPickerView: View {
    @Binding var selectedFontName: String
    let fonts: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            //navigationTitle("Font")
            ZStack {
                DottedBackground().ignoresSafeArea()
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(fonts, id: \.self) { name in
                            Button {
                                selectedFontName = name
                                dismiss()
                            } label: {
                                Text("peekaboo")
                                    .font(.custom(name, size: 20))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Fonts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

