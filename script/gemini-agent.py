import os
import google.generativeai as genai
import subprocess

# 1. Configuration
# Using your API Key from GitHub Secrets
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Using Gemini 1.5 Pro or 2.0 Flash (very capable for coding)
# You can change this string to 'gemini-3-pro' if it is officially 
# released in the API documentation for 2026.
model = genai.GenerativeModel('gemini-1.5-pro')

def run_command(command):
    try:
        return subprocess.check_output(command, shell=True).decode('utf-8')
    except subprocess.CalledProcessError as e:
        print(f"Error executing: {command}\n{e.output.decode()}")
        return ""

def main():
    issue_title = os.getenv("ISSUE_TITLE")
    issue_body = os.getenv("ISSUE_BODY")
    issue_num = os.getenv("ISSUE_NUMBER")
    
    # 2. Prompting Gemini
    prompt = f"""
    Task: {issue_title}
    Details: {issue_body}
    
    Instruction: Act as an expert developer. Modify or create files for this task.
    Return ONLY the code blocks preceded by the filename.
    Format example:
    ---FILE: path/to/file.py---
    CODE START
    ...
    CODE END
    """
    
    response = model.generate_content(prompt)
    ai_output = response.text

    # 3. Git Setup
    branch_name = f"gemini-task-{issue_num}"
    run_command("git config user.name 'github-actions[bot]'")
    run_command("git config user.email 'github-actions[bot]@users.noreply.github.com'")
    run_command(f"git checkout -b {branch_name}")

    # 4. Save Changes
    # For now, we save the full response as a markdown proposal file.
    # This allows you to review the plan as a PR first.
    with open(f"gemini_proposal_issue_{issue_num}.md", "w") as f:
        f.write(f"# Proposal for Issue {issue_num}\n\n{ai_output}")

    # 5. Push and PR
    run_command("git add .")
    run_command(f"git commit -m 'Gemini proposal for #{issue_num}'")
    run_command(f"git push origin {branch_name}")
    
    # Use GitHub CLI to create the PR automatically
    pr_cmd = f"gh pr create --title 'Gemini: {issue_title}' --body 'AI generated changes for #{issue_num}' --head {branch_name}"
    os.system(pr_cmd)

if __name__ == "__main__":
    main()