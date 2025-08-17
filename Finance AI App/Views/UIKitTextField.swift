import SwiftUI
import UIKit

// UIKit TextField wrapped for SwiftUI
struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = autocapitalizationType
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        
        // Force black text on white background
        textField.textColor = .black
        textField.backgroundColor = .white
        textField.layer.borderColor = UIColor.blue.cgColor
        textField.layer.borderWidth = 2
        textField.layer.cornerRadius = 8
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: UIKitTextField
        
        init(_ parent: UIKitTextField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            DispatchQueue.main.async {
                self.parent.text = newText
            }
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

// Wrapper for easier use
struct FixedTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            UIKitTextField(
                text: $text,
                placeholder: placeholder,
                isSecure: isSecure,
                keyboardType: keyboardType,
                autocapitalizationType: autocapitalizationType
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
    }
}

#Preview {
    VStack {
        @State var testText = ""
        FixedTextField(
            text: $testText,
            placeholder: "Test UIKit TextField",
            systemImage: "textfield"
        )
        Text("Current: \(testText)")
    }
    .padding()
}
