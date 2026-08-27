# Git Multiple Email Configuration (Personal + Company Repositories)

## Overview

This guide explains how to use different Git commit email addresses on the same laptop:

- Personal repositories → `mrbalraj@gmail.com`
- Company repositories → `balraj.singh@jetstar.com`

Git automatically switches the email address based on the repository location.

---

## Folder Structure

### Personal Repositories

Stored under:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\Balraj_D_Laptop_Drive\DevOps_Master
```

Example:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\Balraj_D_Laptop_Drive\DevOps_Master\Azure_Image-Builder
```

These repositories use:

```text
mrbalraj@gmail.com
```

### Company Repositories

Stored under:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\JQ_GitHub_Repo_Project
```

Example:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\JQ_GitHub_Repo_Project\a1908-jetstar-azure-snap-on-level-5
```

These repositories use:

```text
balraj.singh@jetstar.com
```

---

## Step 1: Configure Global (Personal) Identity

Set your personal identity as the default Git configuration.

```bash
git config --global user.name "Balraj Singh"
git config --global user.email "mrbalraj@gmail.com"
```

Verify:

```bash
git config --show-origin --get user.email
```

Expected:

```text
file:C:/Users/bsingh/.gitconfig mrbalraj@gmail.com
```

---

## Step 2: Create Company Configuration File

Create the file:

```text
C:\Users\bsingh\.gitconfig-company
```

Contents:

```ini
[user]
    email = balraj.singh@jetstar.com
    name = Balraj Singh
```

---

## Step 3: Update Global .gitconfig

File:

```text
C:\Users\bsingh\.gitconfig
```

Contents:

```ini
[user]
    name = Balraj Singh
    email = mrbalraj@gmail.com

[includeIf "gitdir:C:/Users/bsingh/OneDrive - Jetstar Airways Pty Ltd/JQ_GitHub_Repo_Project/**"]
    path = C:/Users/bsingh/.gitconfig-company
```

---

## Important Learning

The include rule only becomes active when Git is running inside an actual Git repository.

For example, this folder is NOT a Git repository:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\JQ_GitHub_Repo_Project
```

It is only a parent directory that contains repositories.

Example repository:

```text
C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\JQ_GitHub_Repo_Project\a1908-jetstar-azure-snap-on-level-5
```

You must run Git commands from inside the repository folder.

---

## Verify Personal Repository

Navigate to any personal repository:

```bash
cd "C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\Balraj_D_Laptop_Drive\DevOps_Master\Azure_Image-Builder"
```

Check email:

```bash
git config --show-origin --get user.email
```

Expected result:

```text
file:C:/Users/bsingh/.gitconfig mrbalraj@gmail.com
```

---

## Verify Company Repository

Navigate to an actual company repository:

```bash
cd "C:\Users\bsingh\OneDrive - Jetstar Airways Pty Ltd\JQ_GitHub_Repo_Project\a1908-jetstar-azure-snap-on-level-5"
```

Check email:

```bash
git config --show-origin --get user.email
```

Expected result:

```text
file:C:/Users/bsingh/.gitconfig-company balraj.singh@jetstar.com
```

---

## Useful Troubleshooting Commands

Show current email:

```bash
git config user.email
```

Show source of current email:

```bash
git config --show-origin --get user.email
```

Show complete effective configuration:

```bash
git config --list --show-origin
```

Show repository root:

```bash
git rev-parse --show-toplevel
```

Show Git directory:

```bash
git rev-parse --git-dir
```

---

## Final Result

| Repository Type | Email Used |
|----------------|------------|
| Personal Repositories | mrbalraj@gmail.com |
| Jetstar Company Repositories | balraj.singh@jetstar.com |

Git now automatically switches identities based on repository location, preventing accidental commits with the wrong email address.
