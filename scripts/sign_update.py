#!/usr/bin/env python3
"""
Sparkle update signing tool for Ed25519 signatures.
This is a fallback implementation for GitHub Actions.
"""

import sys
import base64
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519
import hashlib

def sign_file(file_path, private_key_path):
    """Sign a file with Ed25519 private key."""
    
    # Load private key
    with open(private_key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    
    if not isinstance(private_key, ed25519.Ed25519PrivateKey):
        raise ValueError("Key is not an Ed25519 private key")
    
    # Read file and create signature
    with open(file_path, 'rb') as f:
        file_data = f.read()
    
    signature = private_key.sign(file_data)
    
    # Return base64 encoded signature
    return base64.b64encode(signature).decode('ascii')

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: sign_update <file> -f <private_key>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    # Parse -f flag
    key_path = None
    for i, arg in enumerate(sys.argv):
        if arg == "-f" and i + 1 < len(sys.argv):
            key_path = sys.argv[i + 1]
            break
    
    if not key_path:
        print("Error: Private key path required with -f flag")
        sys.exit(1)
    
    try:
        signature = sign_file(file_path, key_path)
        print(f"sparkle:edSignature=\"{signature}\"")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)