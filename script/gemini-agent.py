import os
import json
import subprocess
import urllib.request

def main():
    api_key = os.getenv("GEMINI_API_KEY")
    issue_title = os.getenv("ISSUE_TITLE")
    issue_body = os.getenv("ISSUE_BODY")
    issue_num = os.getenv("ISSUE_NUMBER")

    # Wir versuchen zuerst das stabilste Modell für 2026
    # Sollte dies fehlschlagen, listet das Skript Alternativen auf
    model = "gemini-2.5-flash" 
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"

    data = {
        "contents": [{
            "parts": [{"text": f"Task: {issue_title}\nDetails: {issue_body}\n\nReturn ONLY the text/code for the file geminitest.txt."}]
        }]
    }

    req = urllib.request.Request(
        url, 
        data=json.dumps(data).encode("utf-8"), 
        headers={'Content-Type': 'application/json'},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode("utf-8"))
            ai_output = result['candidates'][0]['content']['parts'][0]['text']
            print(f"Erfolg mit {model}!")
    except Exception as e:
        print(f"Fehler mit {model}. Starte Modell-Suche...")
        # NOTFALL-PLAN: Liste verfügbare Modelle auf
        list_url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
        with urllib.request.urlopen(list_url) as list_res:
            models_data = json.loads(list_res.read().decode())
            print("Verfügbare Modelle in deinem Account:")
            for m in models_data.get('models', []):
                print(f" - {m['name']}")
        return

    # Git Workflow
    branch_name = f"gemini-task-{issue_num}"
    subprocess.run("git config user.name 'github-actions[bot]'", shell=True)
    subprocess.run("git config user.email 'github-actions[bot]@users.noreply.github.com'", shell=True)
    subprocess.run(f"git checkout -b {branch_name}", shell=True)

    with open("geminitest.txt", "w") as f:
        f.write(ai_output)

    subprocess.run("git add .", shell=True)
    subprocess.run(f"git commit -m 'Gemini: {issue_title}'", shell=True)
    subprocess.run(f"git push origin {branch_name} --force", shell=True)
    os.system(f"gh pr create --title 'Gemini: {issue_title}' --body 'Closes #{issue_num}' --head {branch_name}")

if __name__ == "__main__":
    main()