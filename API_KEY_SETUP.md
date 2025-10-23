# OpenAI API Key Setup

## 🔐 Secure API Key Configuration

To use the AI features in your Finance AI App, you need to configure your OpenAI API key securely.

### Option 1: Environment Variable (Recommended for Development)

1. Open Terminal
2. Add your API key to your shell profile:
   ```bash
   echo 'export OPENAI_API_KEY="YOUR_ACTUAL_API_KEY_HERE"' >> ~/.zshrc
   ```
3. Restart Terminal or run: `source ~/.zshrc`

### Option 2: UserDefaults (For Testing)

Add this code to your app's initialization (in App.swift or ContentView.swift):

```swift
// Add this in your app's initialization
UserDefaults.standard.set("YOUR_ACTUAL_API_KEY_HERE", forKey: "OpenAI_API_Key")
```

### Option 3: Direct Code (Temporary for Testing)

If you want to test quickly, you can temporarily replace the placeholder in `OpenAIService.swift`:

```swift
return "YOUR_ACTUAL_API_KEY_HERE"
```

## 🚨 Security Notes

- **Never commit API keys to Git repositories**
- **Use environment variables for production**
- **Consider using a secrets management service for production apps**

## ✅ Testing

After setting up your API key, test the AI features:

1. Open the Assistant tab in your app
2. Ask FinBot a question like "How can I save money?"
3. Try the voice expense entry feature

Your API key should now work securely! 🎉
