import firebase_admin
from firebase_admin import credentials
import os
import json


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        # Check if running on Render (production)
        firebase_creds_json = os.getenv('FIREBASE_CREDENTIALS_JSON')

        if firebase_creds_json:
            # Production: Use environment variable
            cred_dict = json.loads(firebase_creds_json)
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            print("Firebase initialized from environment variable")
        else:
            # Development: Use service account file
            cred_path = os.path.join(os.path.dirname(
                __file__), '..', 'firebase-credentials.json')
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                print(f"Firebase initialized from file: {cred_path}")
            else:
                # Fallback: Initialize without credentials (for testing)
                print(
                    "WARNING: Firebase credentials not found. Authentication may not work.")
                firebase_admin.initialize_app()
