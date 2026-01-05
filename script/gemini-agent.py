import os
import sys
from google import genai
import subprocess

# 1. Setup with the NEW library
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

MODEL_ID = "gemini-1.5-flash" 

def run_command(command):
    try:
        return subprocess.check_output(command, shell=True).decode('utf-8')
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.output.decode()}")
        return ""

def main():
    issue_title = os.getenv("ISSUE_TITLE")
    issue_body = os.getenv("ISSUE_BODY")
    issue_num = os.getenv("ISSUE_NUMBER")
    
    prompt = f"Task: {issue_title}\nDetails: {issue_body}\n\nAct as an expert developer. Create the requested file. Return ONLY the code/text for the file."
    
    # 2. Generate Content using the new SDK
    response = client.models.generate_content(
        model=MODEL_ID,
        contents=prompt
    )
    
    ai_output = response.text

    # 3. Git Workflow
    branch_name = f"gemini-task-{issue_num}"
    run_command("git config user.name 'github-actions[bot]'")
    run_command("git config user.email 'github-actions[bot]@users.noreply.github.com'")
    run_command(f"git checkout -b {branch_name}")

    # 4. Save the file (Simplified: saves the AI output to the requested filename)
    # Since your issue asked for 'geminitest.txt', we'll name it that for the test
    with open("geminitest.txt", "w") as f:
        f.write(ai_output)

    # 5. Push and PR
    run_command("git add .")
    run_command(f"git commit -m 'Gemini: {issue_title}'")
    run_command(f"git push origin {branch_name}")
    
    # Create PR via GitHub CLI
    os.system(f"gh pr create --title 'Gemini: {issue_title}' --body 'Closes #{issue_num}' --head {branch_name}")

if __name__ == "__main__":
    main()