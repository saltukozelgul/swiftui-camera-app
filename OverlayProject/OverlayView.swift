//
//  OverlayView.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 7.05.2023.
//

import SwiftUI

extension Color {
  init(_ hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: alpha
    )
  }
}

struct OverlayView: View {
    let orange = Color(0xFBB401)
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Scoreboard")
                        .font(.title)
                    Spacer()
                }
                Text("0 - 0")
                    .padding(.leading, 45.0)
                    .font(.title2)
                Spacer()
            }
            VStack {
                Image("fenzade_logo")
                    .resizable()
                    .frame(width: 50, height: 50)
                Spacer()
            }
        }
        .padding()
        .foregroundColor(orange)
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView()
    }
}
