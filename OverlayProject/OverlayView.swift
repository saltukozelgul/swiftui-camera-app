//
//  OverlayView.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 7.05.2023.
//

import SwiftUI

struct OverlayView: View {
    var body: some View {
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
        .padding()
        .foregroundColor(.cyan)
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView()
    }
}
