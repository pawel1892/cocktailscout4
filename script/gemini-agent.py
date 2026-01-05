import os
import json
import subprocess
import urllib.request

def main():
    api_key = os.getenv("GEMINI_API_KEY")
    issue_title = os.getenv("ISSUE_TITLE")
    issue_body = os.getenv("ISSUE_BODY")
    issue_num = os.getenv("ISSUE_NUMBER")

    # Der direkte Link zur Google API (keine Library nötig!)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"

    # Die Anfrage an die KI
    data = {
        "contents": [{
            "parts": [{"text": f"Task: {issue_title}\nDetails: {issue_body}\n\nReturn ONLY the content for the requested file."}]
        }]
    }

    # Der eigentliche Aufruf
    req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers={'Content-Type': 'application/json'})
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode("utf-8"))
            ai_output = result['candidates'][0]['content']['parts'][0]['text']
    except Exception as e:
        print(f"Fehler beim API-Aufruf: {e}")
        return

    # Git Workflow (wie gehabt)
    branch_name = f"gemini-task-{issue_num}"
    subprocess.run(f"git config user.name 'github-actions[bot]'", shell=True)
    subprocess.run(f"git config user.email 'github-actions[bot]@users.noreply.github.com'", shell=True)
    subprocess.run(f"git checkout -b {branch_name}", shell=True)

    with open("geminitest.txt", "w") as f:
        f.write(ai_output)

    subprocess.run("git add .", shell=True)
    subprocess.run(f"git commit -m 'Gemini: {issue_title}'", shell=True)
    subprocess.run(f"git push origin {branch_name}", shell=True)
    os.system(f"gh pr create --title 'Gemini: {issue_title}' --body 'Closes #{issue_num}' --head {branch_name}")

if __name__ == "__main__":
    main()