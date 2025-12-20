# Tailscale Setup for AirFit

This guide explains how to set up Tailscale so the AirFit iOS app can connect to your server from anywhere (home, work, or on cellular).

## Why Tailscale?

- **Works everywhere**: Connect to your server from any network (home WiFi, work WiFi, cellular)
- **No port forwarding**: Your router doesn't need configuration
- **Secure**: End-to-end WireGuard encryption
- **Free tier**: 3 users, 100 devices (perfect for family)

---

## Step 1: Set Up Tailscale on Your Server (Mac/Raspberry Pi)

### On macOS:

```bash
# Install via Homebrew
brew install tailscale

# Start the Tailscale service
sudo tailscaled &

# Authenticate and connect
tailscale up

# Set a friendly hostname for MagicDNS
sudo tailscale set --hostname airfit-server
```

### On Raspberry Pi:

```bash
# Install Tailscale (one-line installer)
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and connect
sudo tailscale up

# Set a friendly hostname for MagicDNS
sudo tailscale set --hostname airfit-server

# Verify it's working
tailscale status
```

After setup, your server will be accessible at: `http://airfit-server:8080`

---

## Step 2: Install Tailscale on iOS Devices

1. **Download** [Tailscale from the App Store](https://apps.apple.com/app/tailscale/id1470499037)
2. **Sign in** with the same account you used on the server
3. **Toggle ON** the Tailscale VPN when using AirFit

> **Note**: iOS limits one VPN at a time. If you use another VPN, you'll need to disconnect it while using AirFit.

---

## Step 3: Configure AirFit

When you first launch AirFit, you'll be asked for the server address:

- **Scan QR Code**: Use the QR code you generate (see below)
- **Manual Entry**: Enter `http://airfit-server:8080`

---

## Generate a QR Code for Family Members

Create a QR code that your family can scan to instantly configure their AirFit app:

### Using qrencode CLI:

```bash
# Install qrencode (macOS)
brew install qrencode

# Generate QR code image
qrencode -o airfit-server-qr.png "airfit://server?url=http://airfit-server:8080"

# Open it
open airfit-server-qr.png
```

### Using Online Generator:

Go to any QR code generator website and create a QR code with this text:

```
airfit://server?url=http://airfit-server:8080
```

Share the QR image via iMessage or AirDrop to family members.

---

## Invite Family Members to Your Tailnet

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin)
2. Click **Users** → **Invite users**
3. Enter their email address
4. They'll receive an invite to join your network

### Free Tier Limits:
- **3 users** (you + 2 family members)
- **100 devices**

Need more users? Upgrade to Personal Plus ($48/year) for 6 users.

---

## Troubleshooting

### "Cannot connect to server"

1. **Is Tailscale connected?**
   - Open Tailscale app on iOS
   - Make sure the toggle is ON
   - Check that you see your devices listed

2. **Is the server running?**
   ```bash
   cd /path/to/AirFit/server
   python server.py
   ```

3. **Is Tailscale running on the server?**
   ```bash
   tailscale status
   # Should show "airfit-server" and your device
   ```

4. **Can you ping the server?**
   ```bash
   # From another Tailscale device
   ping airfit-server
   ```

### "Connection works on WiFi but not cellular"

1. Ensure Tailscale is connected (green status)
2. Try disconnecting and reconnecting Tailscale
3. Check that your cellular data is enabled

### DNS Resolution Issues

If `airfit-server` doesn't resolve:

1. Use the Tailscale IP instead (e.g., `http://100.64.1.5:8080`)
2. Find your server's Tailscale IP:
   ```bash
   tailscale ip
   ```
3. Update the AirFit app with this IP in Settings

---

## Running the Server on Startup (Raspberry Pi)

Create a systemd service so the server starts automatically:

```bash
sudo nano /etc/systemd/system/airfit.service
```

Paste:

```ini
[Unit]
Description=AirFit Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/AirFit/server
ExecStart=/home/pi/AirFit/server/venv/bin/python server.py
Restart=on-failure
Environment=HEVY_API_KEY=your_hevy_api_key_here

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable airfit
sudo systemctl start airfit

# Check status
sudo systemctl status airfit
```

---

## Quick Reference

| What | Command/URL |
|------|-------------|
| Server URL (MagicDNS) | `http://airfit-server:8080` |
| Server URL (IP fallback) | `http://100.x.x.x:8080` |
| QR Code Content | `airfit://server?url=http://airfit-server:8080` |
| Tailscale Admin | https://login.tailscale.com/admin |
| Check server status | `curl http://airfit-server:8080/status` |

---

## Alternative: Local Network Only

If you don't want to use Tailscale and only use AirFit on your home network:

1. Find your server's local IP:
   ```bash
   # macOS
   ipconfig getifaddr en0

   # Raspberry Pi
   hostname -I
   ```

2. Configure AirFit with `http://192.168.x.x:8080`

**Limitations**:
- Only works on your home WiFi
- Won't work from work, coffee shops, or on cellular
- IP may change if router reassigns it

For reliable access, Tailscale is recommended.
