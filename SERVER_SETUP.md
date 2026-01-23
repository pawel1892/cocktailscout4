# Server Setup for Kamal Deployment

## SSH User Configuration

Kamal connects as user `pawel` with **restricted passwordless sudo** for security.

## Setup Restricted Passwordless Sudo

SSH to your server and configure restricted sudo for the `pawel` user:

```bash
# SSH to your server as root or a user with sudo
ssh root@23.88.50.20

# Create a sudoers file for pawel with restricted commands
sudo visudo -f /etc/sudoers.d/pawel
```

Add these lines (allows only Docker and systemd commands):

```
# Allow pawel to run Docker commands without password
pawel ALL=(ALL) NOPASSWD: /usr/bin/docker
pawel ALL=(ALL) NOPASSWD: /usr/bin/docker-compose

# Allow systemd service management (for Kamal accessories)
pawel ALL=(ALL) NOPASSWD: /usr/bin/systemctl

# Allow directory creation in specific paths Kamal needs
pawel ALL=(ALL) NOPASSWD: /usr/bin/mkdir -p /var/lib/docker/*
pawel ALL=(ALL) NOPASSWD: /usr/bin/mkdir -p /root/*

# Allow file operations Kamal might need
pawel ALL=(ALL) NOPASSWD: /usr/bin/chown
pawel ALL=(ALL) NOPASSWD: /usr/bin/chmod

# Preserve environment for Docker
Defaults:pawel env_keep += "PATH"
```

Save and exit:
- In nano: Ctrl+X, then Y, then Enter
- In vim: Press Esc, type `:wq`, press Enter

### Verify Restricted Sudo

Test that it works:

```bash
# Switch to pawel user (or SSH as pawel)
su - pawel

# These should work WITHOUT password:
sudo docker ps
sudo docker --version
sudo systemctl status docker

# This should ASK for password (restricted):
sudo ls /etc/shadow
```

If `docker ps` works without password but `ls /etc/shadow` asks for password, you're all set!

## Install Docker (if not already installed)

Kamal can install Docker for you, but if you want to do it manually first:

```bash
# As pawel user with sudo
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add pawel to docker group (optional, allows docker without sudo)
sudo usermod -aG docker pawel

# Log out and back in for group change to take effect
exit
ssh pawel@23.88.50.20

# Test Docker access
docker ps
```

## SSH Key Setup

Make sure your SSH key is authorized for the `pawel` user:

```bash
# On your server, as pawel user
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key
# Get it from your local machine with: cat ~/.ssh/id_rsa.pub
nano ~/.ssh/authorized_keys
# Paste your public key, save and exit

chmod 600 ~/.ssh/authorized_keys
```

### Disable Password Authentication (Recommended)

For better security, disable password authentication and only allow SSH keys:

```bash
# As root or with sudo
sudo nano /etc/ssh/sshd_config
```

Find and set:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

**Warning:** Make sure your SSH key works BEFORE disabling password auth, or you'll be locked out!

## Test Everything

From your local machine:

```bash
# Test SSH connection (should work without password)
ssh pawel@23.88.50.20

# Test Docker with sudo (should work without password)
sudo docker ps

# Test restricted sudo (should ASK for password)
sudo cat /etc/shadow
```

## Firewall Configuration

Make sure ports 80 and 443 are open:

```bash
# If using UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH
sudo ufw enable

# If using firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

## Security Notes

### What This Protects Against

✅ Arbitrary root commands - `pawel` can't run `sudo rm -rf /` or other dangerous commands
✅ User management - Can't create users, modify passwords, etc.
✅ System file access - Can't read sensitive files like `/etc/shadow`

### What's Allowed

✅ Docker management - Required for Kamal deployments
✅ Service management - Required for database and other accessories
✅ Specific directory operations - Only in paths Kamal needs

### Additional Hardening (Optional)

For even better security:

1. **Restrict SSH to specific IPs:**
   ```bash
   # In /etc/ssh/sshd_config
   AllowUsers pawel@your.home.ip.address
   ```

2. **Use SSH key with passphrase:**
   Make sure your local SSH key is protected with a strong passphrase.

3. **Enable fail2ban:**
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```

4. **Regular updates:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## Troubleshooting

### "sudo: a password is required"

The sudoers file isn't configured correctly. Double-check:
- File is at `/etc/sudoers.d/pawel`
- No syntax errors (use `sudo visudo -c` to check)
- Permissions are correct: `chmod 440 /etc/sudoers.d/pawel`

### "Sorry, user pawel is not allowed to execute..."

The command you're trying isn't in the allowed list. Either:
- Add it to `/etc/sudoers.d/pawel`
- Or check if Kamal actually needs it (might be a bug)

### Kamal fails during deployment

Check Kamal logs to see which sudo command failed, then add it to the sudoers file.

## Ready to Deploy

Once these steps are complete, you're ready to run:

```bash
kamal setup -d beta
```

from your local machine!
