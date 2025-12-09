import ollama
import sys

print("Testing Ollama Connection...")
try:
    models_response = ollama.list()
    print("Success! Ollama is reachable.")
    print(f"Response keys: {models_response.keys()}")
    
    models = [model.get('model') or model.get('name') for model in models_response.get('models', [])]
    print(f"Available Models: {models}")
    
    required_model = "phi3:mini"
    if required_model in models:
        print(f"✅ Required model '{required_model}' is present.")
    else:
        print(f"❌ Required model '{required_model}' is MISSING.")
        print("Attempting to pull model...")
        # Optional: ollama.pull(required_model)
        
except Exception as e:
    print(f"❌ Connection Failed: {e}")
    sys.exit(1)
