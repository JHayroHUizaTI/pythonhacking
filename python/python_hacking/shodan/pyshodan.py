"""
Shodan API - Search Engine for Internet-Connected Devices
Initializes the Shodan API using an API key from environment variables.
"""

import shodan
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the API key from environment variable
SHODAN_API_KEY = os.getenv("SHODAN_API_KEY")

if not SHODAN_API_KEY:
    print("[!] Error: SHODAN_API_KEY not found in environment variables.")
    print("[*] Set it in your .env file: SHODAN_API_KEY=your_api_key_here")
    exit(1)

# Initialize the Shodan API
api = shodan.Shodan(SHODAN_API_KEY)

try:
    # Test the API connection by fetching account info
    info = api.info()
    print(f"[+] Shodan API initialized successfully!")
    print(f"    Scan credits  : {info.get('scan_credits', 'N/A')}")
    print(f"    Query credits  : {info.get('query_credits', 'N/A')}")
    print(f"    Plan           : {info.get('plan', 'N/A')}")

except shodan.APIError as e:
    print(f"[!] Shodan API Error: {e}")
