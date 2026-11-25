import urllib.request
import json
import uuid

apk_path = r"d:\Design thinking\build\app\outputs\flutter-apk\app-debug.apk"
url = "https://tmpfiles.org/api/v1/upload"

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

req = urllib.request.Request(url, data=bytes(body), headers=headers, method='POST')
try:
    with urllib.request.urlopen(req) as resp:
        res_text = resp.read().decode('utf-8')
        data = json.loads(res_text)
        page_url = data["data"]["url"]
        dl_url = page_url.replace("tmpfiles.org/", "tmpfiles.org/dl/")
        print("DIRECT_DOWNLOAD_URL=" + dl_url)
except Exception as e:
    print("Error:", e)
