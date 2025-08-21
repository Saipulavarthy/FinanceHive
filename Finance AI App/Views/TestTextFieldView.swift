import SwiftUI

struct TestTextFieldView: View {
    @State private var testText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Text Field Test")
                .font(.title)
                .padding()
            
            // Test 1: Basic TextField
            VStack {
                Text("Test 1: Basic TextField")
                TextField("Type here", text: $testText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Current text: '\(testText)'")
                    .foregroundColor(.blue)
            }
            .padding()
            .border(Color.red, width: 1)
            
            // Test 2: Completely custom TextField
            VStack {
                Text("Test 2: Custom TextField")
                TextField("Type here", text: $testText)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .border(Color.black, width: 2)
                Text("Current text: '\(testText)'")
                    .foregroundColor(.green)
            }
            .padding()
            .border(Color.blue, width: 1)
            
            // Test 3: Raw text field without any styling
            VStack {
                Text("Test 3: Raw TextField")
                TextField("Type here", text: $testText)
                Text("Current text: '\(testText)'")
                    .foregroundColor(.purple)
            }
            .padding()
            .border(Color.green, width: 1)
            
            // Test 4: UIKit TextField (SHOULD WORK!)
            VStack {
                Text("Test 4: UIKit TextField")
                FixedTextField(
                    text: $testText,
                    placeholder: "UIKit should work!",
                    systemImage: "checkmark.circle"
                )
                Text("Current text: '\(testText)'")
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
            }
            .padding()
            .border(Color.orange, width: 2)
            
            Spacer()
            
            // Navigation button to main app
            NavigationLink(destination: ContentView()) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Go to Main App")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    TestTextFieldView()
}
