//
//  CustomBackgroundView.swift
//  Hike
//
//  Created by Abhishek on 08/03/25.
//

import SwiftUI

struct CustomBackgroundView: View {
    var body: some View {
        ZStack {
            // MARK: - 3. DEPTH
            
            Color.customGreenDark
                .cornerRadius(40)
                .offset(y: 12)
            
            // MARK: - 2. LIGHT
            
            Color.customGreenLight
                .cornerRadius(40)
                .offset(y: 12)
                .opacity(0.85)
            
            
            // MARK: - 1. SURFACE
            LinearGradient(
                colors: [
                    .customGreenLight,
                    .customGreenMedium],
                startPoint: .top,
                endPoint: .bottom
            ).cornerRadius(40)
        }
    }
}

// write preview 4:34
#Preview {
    CustomBackgroundView()
        .padding()
}
