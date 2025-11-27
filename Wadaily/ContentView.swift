//
//  ContentView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "globe")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView()
}
