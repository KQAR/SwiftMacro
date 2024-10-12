//
//  ContentView.swift
//  MacroExample
//
//  Created by Jarvis on 2024/9/27.
//

import SwiftUI

struct ContentView: View {
  let x = ""
  let y = ""
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }

  func test() {
    #stringify(x + y)
  }
}

#Preview {
    ContentView()
}
