//
//  GradientButtonStyle.swift
//  Hike
//
//  Created by Abhishek on 12/04/25.
//

import Foundation
import SwiftUI

struct GradientButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.vertical)
            .padding(.horizontal, 30)
            .background(
                // Conditional Statement with nil-coalescing operator
                // Condition ? A : B
                configuration.isPressed ?
                // A: When the user press the button
                LinearGradient(colors: [.customGrayMedium, .customGrayLight], startPoint: .top, endPoint: .bottom) : 
                // B: When the button is not pressed
                LinearGradient(colors: [.customGrayLight, .customGrayMedium], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(40)
    }
}
