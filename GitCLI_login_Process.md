# Step‑by‑step guide to log in to GitHub using the gh CLI. 



1. **Check if gh is installed**
Open your terminal and run:
```Shell
gh --version
```

If not installed:

Windows: 

```shell
winget install --id GitHub.cli
```

Linux (Ubuntu/Debian):
```Shell
sudo apt install gh
```



2. **Start the login process**
Run:
```Shell
gh auth login
```
This launches an interactive setup.

3. **Answer the prompts (recommended choices)**
   
- It’ll be asked a series of questions. 
- Typical and recommended answers are shown below.
  
**3.1 GitHub.com or GitHub Enterprise?**
```shell
? What account do you want to log into?
❯ GitHub.com
  GitHub Enterprise Server
```
Choose `GitHub.com` (unless you use Enterprise).

**3.2 Preferred protocol**
```shell
? What is your preferred protocol for GitHub operations?
❯ HTTPS
  SSH
```

```sh
HTTPS → easiest for most users
SSH → choose only if you already use SSH keys with GitHub
```

Choose `HTTPS` if unsure.

**3.3 Authenticate Git?**

`? Authenticate Git with your GitHub credentials? (Y/n)`

Press `Y`
- This sets git to use gh for auth (recommended).

**3.4 Authentication method**
```shell
? How would you like to authenticate GitHub CLI?
❯ Login with a web browser  
```
Choose Login with a web browser (simplest & safest)

**4. Complete browser authentication**
- After choosing browser login, you’ll see something like:
```shell
! First copy your one-time code: XXXX-XXXX
Press Enter to open github.com in your browser...
```
- **Steps:**

1. **Press Enter** → browser opens automatically
2. **Sign in to GitHub** (if not already)
3. **Paste the one-time code** shown in your terminal
4. **Authorize GitHub CLI**

Once complete, your terminal will confirm success.

**5. Verify login**
Run:
```Shell
gh auth status
```
*Expected output:*

- Logged in to `GitHub.com`
- Token has required scopes

**Example:**
```shell
github.com
  - ✓ Logged in as `your-username`
  - ✓ Git operations for github.com configured to use `https`
```

**Clone the repo**
```sh
git clone <repo>
```