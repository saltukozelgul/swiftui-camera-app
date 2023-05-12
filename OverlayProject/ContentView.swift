//
//  ContentView.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 7.05.2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
            HostedViewController()
                .ignoresSafeArea()
                .overlay(OverlayView())
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
