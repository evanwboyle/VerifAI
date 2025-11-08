//
//  RestrictOverlayView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI

struct RestrictOverlayView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.3, blue: 0.3),
                    Color(red: 0.85, green: 0.2, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Lock Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                // Title
                VStack(spacing: 12) {
                    Text("App Restricted")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("This app has been blocked by VerifAI")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Message
                VStack(spacing: 12) {
                    Text("You're focusing on what matters most. This app is temporarily restricted to help you stay productive.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundColor(.white)
                        Text("Restrictions active 24/7")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Open VerifAI app
                        if let url = URL(string: "verifai://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Open VerifAI")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                        .cornerRadius(12)
                    }

                    Button(action: { dismiss() }) {
                        Text("Dismiss")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    RestrictOverlayView()
}
