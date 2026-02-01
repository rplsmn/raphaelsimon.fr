# Blog Topic Analyzer - Raspberry Pi Setup

Deploy the Obsidian vault analyzer on a Raspberry Pi 4 with USB SSD storage.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR DEVICES                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Laptop   │  │  iPhone  │  │   iPad   │                       │
│  │ Obsidian │  │ Obsidian │  │ Obsidian │                       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │
│       │             │             │                              │
│       └─────────────┴─────────────┘                              │
│                     │                                            │
│              Dropbox Sync (native)                               │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DROPBOX CLOUD                             │
│                     /Obsidian/Vault/                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ rclone sync (every 15 min)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI 4 (4GB)                          │
│                    {{PI_HOSTNAME}}                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ USB SSD (1TB)                                            │    │
│  │                                                          │    │
│  │  ~/vault/           <- synced Obsidian vault             │    │
│  │  ~/analyzer/        <- analysis scripts                  │    │
│  │  ~/analyzer/logs/   <- run logs                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Cron jobs:                                                      │
│  - rclone sync      every 15 min                                │
│  - analyze_vault.py daily at 09:00                              │
│                                                                  │
│  Notifications: Telegram / Discord                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Power Considerations

USB SSDs draw significant power, especially during writes:

| State | SSD Power Draw | Pi 4 Base | Total |
|-------|----------------|-----------|-------|
| Idle | ~1-2W | ~3W | ~4-5W |
| Read | ~2-3W | ~3W | ~5-6W |
| Write | ~5-8W | ~4W | ~9-12W |

**Requirements:**
- Use the official Raspberry Pi 15W (5V/3A) USB-C power supply, or better
- A cheap phone charger (5V/2A) will cause instability and filesystem corruption
- If using a USB-A SSD with adapter, prefer a powered USB hub for safety

**Power-saving tweaks (optional):**

```bash
# Reduce USB power when idle (may cause issues with some SSDs)
echo 'auto' | sudo tee /sys/bus/usb/devices/*/power/control

# Or just accept the ~5W idle draw - still cheaper than the laptop
```

---

## 2. SD to SSD Migration

### Prerequisites

- 1TB USB SSD (USB-A or USB-C)
- Adequate power supply (see above)
- SSH access to Pi or keyboard/monitor

### Steps

```bash
# SSH into the Pi
ssh {{PI_USER}}@{{PI_HOSTNAME}}

# Install rpi-clone
git clone https://github.com/billw2/rpi-clone.git
cd rpi-clone
sudo cp rpi-clone /usr/local/bin/

# Plug in SSD, identify device
lsblk
# Look for your SSD, likely /dev/sda (NOT /dev/mmcblk0, that's the SD)

# Clone SD card to SSD (10-30 min)
sudo rpi-clone sda

# When prompted, confirm the clone
# Wait for completion

# Shutdown
sudo shutdown now
```

**After shutdown:**
1. Unplug power
2. Remove SD card (store it as backup)
3. Power back on - Pi 4 boots from USB by default

**Verify:**
```bash
ssh {{PI_USER}}@{{PI_HOSTNAME}}
lsblk
# Root filesystem should now be on /dev/sda2
df -h
# Should show ~1TB available
```

---

## 3. Dropbox + rclone Setup

### Install rclone

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure Dropbox remote
rclone config
```

When prompted:
1. `n` for new remote
2. Name: `dropbox`
3. Storage type: search for `dropbox` (or enter number)
4. Client ID: leave blank (uses rclone's)
5. Client secret: leave blank
6. Advanced config: `n`
7. Auto config: `n` (headless server)

You'll get a URL. Open it on your laptop, authorize, paste the token back.

### Configure vault sync

```bash
# Create vault directory
mkdir -p ~/vault

# Test sync (replace path with your Dropbox vault location)
rclone sync dropbox:Obsidian/Vault ~/vault --progress

# Verify
ls ~/vault
```

### Set up cron job

```bash
crontab -e
```

Add:
```cron
# Sync vault every 15 minutes
*/15 * * * * rclone sync dropbox:{{DROPBOX_VAULT_PATH}} ~/vault --quiet --log-file=/home/{{PI_USER}}/analyzer/logs/rclone.log

# Run analyzer daily at 09:00
0 9 * * * /home/{{PI_USER}}/analyzer/analyze_vault.py --vault /home/{{PI_USER}}/vault --notify >> /home/{{PI_USER}}/analyzer/logs/analyzer.log 2>&1
```

**Why 15 minutes instead of 5?**
- Reduces SSD writes (less wear, though SSD wear is negligible)
- Reduces API calls to Dropbox
- Your notes don't need real-time sync for daily analysis
- Can always trigger manual sync: `rclone sync dropbox:Obsidian/Vault ~/vault`

---

## 4. Analyzer Setup

### Install dependencies

```bash
# Create analyzer directory
mkdir -p ~/analyzer/logs

# Copy analyzer script (or clone this repo)
scp tools/analyze_vault.py {{PI_USER}}@{{PI_HOSTNAME}}:~/analyzer/

# Install Python dependencies
pip install anthropic
```

### Configure environment

```bash
# Add to ~/.bashrc or create ~/analyzer/.env
export ANTHROPIC_API_KEY="sk-ant-..."
export TELEGRAM_BOT_TOKEN="123456:ABC..."
export TELEGRAM_CHAT_ID="your_chat_id"
```

For cron to pick up the variables, either:

**Option A:** Source in crontab
```cron
0 9 * * * . /home/{{PI_USER}}/analyzer/.env && /home/{{PI_USER}}/analyzer/analyze_vault.py --vault /home/{{PI_USER}}/vault --notify
```

**Option B:** Wrapper script

```bash
# ~/analyzer/run.sh
#!/bin/bash
source /home/{{PI_USER}}/analyzer/.env
python3 /home/{{PI_USER}}/analyzer/analyze_vault.py --vault /home/{{PI_USER}}/vault --notify
```

```bash
chmod +x ~/analyzer/run.sh
```

Crontab:
```cron
0 9 * * * /home/{{PI_USER}}/analyzer/run.sh >> /home/{{PI_USER}}/analyzer/logs/analyzer.log 2>&1
```

---

## 5. Telegram Bot Setup

1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Send `/newbot`
3. Follow prompts, get your bot token
4. Message your new bot (required to initialize chat)
5. Get your chat ID:
   ```bash
   curl "https://api.telegram.org/bot{{TELEGRAM_BOT_TOKEN}}/getUpdates"
   ```
   Look for `"chat":{"id":123456789}`

---

## 6. Obsidian Device Configuration

### Desktop (Mac/Windows/Linux)

1. Open Obsidian Settings → Files & Links
2. Set vault location to your Dropbox folder, e.g.:
   - Mac: `~/Dropbox/Obsidian/Vault`
   - Windows: `C:\Users\You\Dropbox\Obsidian\Vault`

### iOS

1. Open Obsidian → Create/Open Vault
2. Choose "Store in Dropbox"
3. Authenticate with Dropbox
4. Select your vault folder

### Android

Same as iOS - native Dropbox support in Obsidian.

---

## 7. Testing

### Manual sync test

```bash
ssh {{PI_USER}}@{{PI_HOSTNAME}}

# Force sync
rclone sync dropbox:{{DROPBOX_VAULT_PATH}} ~/vault --progress

# Check vault
ls -la ~/vault
```

### Manual analyzer test

```bash
# Dry run (shows clusters without Claude API call)
python3 ~/analyzer/analyze_vault.py --vault ~/vault --dry-run

# Full run (calls Claude, no notification)
python3 ~/analyzer/analyze_vault.py --vault ~/vault

# Full run with notification
python3 ~/analyzer/analyze_vault.py --vault ~/vault --notify
```

---

## 8. Maintenance

### Check logs

```bash
# Recent analyzer runs
tail -50 ~/analyzer/logs/analyzer.log

# Recent syncs
tail -50 ~/analyzer/logs/rclone.log
```

### Update analyzer

```bash
cd ~/analyzer
# Pull latest or scp new version
```

### Monitor disk health

```bash
# SSD health (if smartmontools installed)
sudo apt install smartmontools
sudo smartctl -a /dev/sda
```

---

## Placeholder Reference

Replace these placeholders with your actual values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{PI_HOSTNAME}}` | Pi's hostname or IP | `raspberrypi.local` or `192.168.1.50` |
| `{{PI_USER}}` | Your Pi username | `pi` or `raphael` |
| `{{DROPBOX_VAULT_PATH}}` | Path to vault in Dropbox | `Obsidian/Vault` or `Apps/Obsidian/MyVault` |
| `{{TELEGRAM_BOT_TOKEN}}` | From BotFather | `123456789:ABCdefGHI...` |
| `{{TELEGRAM_CHAT_ID}}` | Your Telegram user ID | `987654321` |
| `{{ANTHROPIC_API_KEY}}` | From console.anthropic.com | `sk-ant-api03-...` |

---

## Cost Summary

| Item | Cost |
|------|------|
| Raspberry Pi 4 | Already owned |
| 1TB USB SSD | Already owned |
| Dropbox (2GB free tier) | $0 |
| Anthropic API (~1 call/day, Haiku) | ~$1-3/month |
| Electricity (~5W × 24h × 30d) | ~$0.50/month |
| **Total** | **~$1.50-3.50/month** |

Compared to Obsidian Sync alone ($8/month), this setup is cheaper AND gives you automated analysis.
