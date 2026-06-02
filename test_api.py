#!/usr/bin/env python
import urllib.request
import json

url = 'http://127.0.0.1:5000/consultas'
headers = {'Authorization': 'Bearer test', 'Content-Type': 'application/json'}

req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        status = response.status
        body = response.read().decode('utf-8')
        print(f"Status: {status}")
        print(f"Response:\n{body[:500]}")
except Exception as e:
    print(f"Error: {type(e).__name__}")
    print(f"Message: {str(e)[:300]}")
