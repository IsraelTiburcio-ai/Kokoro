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
            TabView {
                Tab("Meditación", systemImage: "apple.meditate") {
                    MeditationHubView()
                }

                
                
                Tab("Juegos", systemImage: "gamecontroller.circle") {
                    JuegosView()
                }
                
                
                Tab("Logros y metas", systemImage: "checkmark.seal.text.page.fill") {
                    LogrosViews()
                }   
                
                Tab("Personas cercanas", systemImage: "person") {
                    EmergencyContactsView()
                    
                }
            }

        }
    }
}

#Preview {
    ContentView()
}
