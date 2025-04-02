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
            
            
            
            // MARK: - 2. LIGHT
            
            // MARK: - 1. SURFACE
            LinearGradient(
                colors: [
                    Color("ColorGreenLight"),
                    Color("ColorGreenMedium")],
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
