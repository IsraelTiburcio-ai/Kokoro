//
//  ContentView.swift
//  Kokoro
//
//  Created by Israel Tiburcio Suchil on 23/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "heart")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("kokoro!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
