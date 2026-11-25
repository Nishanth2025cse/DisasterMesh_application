import urllib.request
import json

apk_path = r"d:\Design thinking\build\app\outputs\flutter-apk\app-release.apk"
bucket = "silentsos-7d50a.firebasestorage.app"
url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o?name=DisasterMesh-App.apk"

headers = {
    'User-Agent': 'Mozilla/5.0',
    'Content-Type': 'application/vnd.android.package-archive'
}

with open(apk_path, "rb") as f:
    file_bytes = f.read()

req = urllib.request.Request(url, data=file_bytes, headers=headers, method='POST')
try:
    with urllib.request.urlopen(req, timeout=300) as resp:
        res_text = resp.read().decode('utf-8')
        data = json.loads(res_text)
        name = data.get("name", "")
        token = data.get("downloadTokens", "")
        download_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{name}?alt=media"
        if token:
            download_url += f"&token={token}"
        print("FIREBASE_STORAGE_DIRECT_APK_URL=" + download_url)
except Exception as e:
    print("Error:", e)
