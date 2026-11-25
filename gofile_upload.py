import urllib.request
import json
import uuid

apk_path = r"d:\Design thinking\DisasterMesh-App.apk"

# Step 1: Get best server
try:
    req_server = urllib.request.Request("https://api.gofile.io/servers", headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req_server) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        server = data["data"]["servers"][0]["name"]
        print("Using GoFile Server:", server)
except Exception as e:
    print("Server fetch error:", e)
    server = "store1"

# Step 2: Upload file
upload_url = f"https://{server}.gofile.io/contents/uploadfile"
boundary = '----WebKitFormBoundary' + uuid.uuid4().hex
headers = {'User-Agent': 'Mozilla/5.0', 'Content-Type': f'multipart/form-data; boundary={boundary}'}

with open(apk_path, "rb") as f:
    file_bytes = f.read()

body = bytearray()
body.extend(f'--{boundary}\r\n'.encode('utf-8'))
body.extend(f'Content-Disposition: form-data; name="file"; filename="DisasterMesh-App.apk"\r\n'.encode('utf-8'))
body.extend(b'Content-Type: application/vnd.android.package-archive\r\n\r\n')
body.extend(file_bytes)
body.extend(f'\r\n--{boundary}--\r\n'.encode('utf-8'))

req = urllib.request.Request(upload_url, data=bytes(body), headers=headers, method='POST')
try:
    with urllib.request.urlopen(req) as resp:
        res_text = resp.read().decode('utf-8')
        print("Upload Response:", res_text)
        res_data = json.loads(res_text)
        if "data" in res_data and "downloadPage" in res_data["data"]:
            print("GOFILE_PAGE=" + res_data["data"]["downloadPage"])
except Exception as e:
    print("Upload error:", e)
