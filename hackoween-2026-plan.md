# Hackoween 2026 — Main-Stage Demonstration Plan

**Date:** October 20, 2026
**Format:** Halloween-themed, presenter-led **live demonstration** — one attacker walks a single victim through a full kill chain on a projected screen while a defender narrates the alerts each step trips. Audience watches; no rotation, no hands-on, no scoring.
**Audience:** conference / public (skews technical).
**Scope:** Everything runs on isolated lab infrastructure shown on screen only. No real systems, no real accounts, and no audience devices are ever involved — attendees only watch.

## Ground rules (finalize before build)

- [ ] Written rules-of-engagement / scope statement, stated aloud in the intro
- [ ] Dedicated isolated network segment (host-only/VLAN), no bridge to conference Wi-Fi or any production system
- [ ] "Golden snapshot" of every VM with a one-command revert, so the room can be reset between rehearsal and show (or for a re-run)
- [ ] Blue-team callout at every act: what log/alert the step generates and how a defender catches it — spoken by the defender narrator (this is the whole point of the talk)
- [ ] Benign, self-contained payloads only (local flag-drops, dummy data) — technique + detection, never a copy-paste weaponization recipe

## The demonstration — one kill chain, told as a story

Single victim VM, projected. Recommended layout: **three panes on screen at once** —

- **Attacker console** (what the operator does)
- **Victim desktop** (what happens to the target)
- **Defender view** — a SIEM/EDR alert feed (what a blue team sees)

The audience sees cause → effect → detection simultaneously. That split-screen *is* the teaching device.

**Presenters:** two works best — a **Red** operator driving the attack and a **Blue** narrator calling out each detection as it fires. One presenter can cover both by pausing to switch focus between panes.

### Act 1 — Initial access → foothold: USB to portable RustDesk
- **What the audience sees:** the operator plugs the Flipper into the victim; it types one line into a **visible** PowerShell window that pulls a bootstrap from the lab web server. Seconds later a portable RustDesk client is running and its ID appears in the operator's console. One motion: physical access straight to remote control.
- **Beat:** *physical access = code execution*, and ten seconds later the machine is being driven from across the room. No admin required.
- **How it works (all user-level, no elevation):** the Flipper (US keyboard layout) types a short `iwr … | iex` cradle → `stage.ps1` on the lab web server (`10.13.37.5`) downloads the **portable** `rustdesk.exe` into `%TEMP%` and a per-user config into `%APPDATA%\RustDesk\config\`, then launches it as the logged-in user. No installer, no service, no UAC. RustDesk points at the lab rendezvous server (hbbs), never the public relay. Artifacts live in `demo-lab/` (`act1-badusb.txt`, `stage.ps1`, `RustDesk2.toml`).
- **Why user-level (not the installer):** the repo's `Install-RustDesk.ps1` is an admin fleet installer (service + Program Files) — deliberately *not* used here. Running portable as the current user avoids UAC entirely and is the sharper teaching point: the attacker never needed admin.
- **Blue callouts (this act is loud despite no admin):**
  - A brand-new HID keyboard that instantly spawns PowerShell — no human types that fast.
  - A `powershell` download cradle (`iwr … | iex`) — script-block logging (4104) + process creation.
  - A remote-access binary running out of `%APPDATA%`/`%TEMP%` — an unexpected, often unsigned exe in a user directory.
  - Outbound beaconing to a non-corporate rendezvous host on a regular interval.

### Act 2 — Defense evasion: AV/EDR tamper
- **What the audience sees:** the operator tries to disable local protection on the victim VM from the foothold.
- **Beat:** attackers try to go dark — but *evasion attempts are loud if you're watching.*
- **Framing:** toggle AV settings only on the lab-controlled VM; the payoff is the resulting **tamper-protection alert**, the star of this act — not a generalizable bypass recipe.
- **Blue callout:** EDR tamper-protection / defense-disable alert fires in the defender pane the instant the attempt is made.

### Act 3 — Post-exploitation: the loot round
Off the same Act 1 foothold, showing that one compromise cascades. Some hits are run manually from PowerShell for effect (`demo-lab/grab-screen.ps1`, `demo-lab/capture-webcam.ps1`); the captured files are saved to the victim Desktop and auto-open so the audience sees them appear.

- **Desktop screenshot** — pure-PowerShell GDI capture of the whole desktop (`grab-screen.ps1`), popped open on screen.
  - *Blue callout:* process calling desktop-capture APIs (`CopyFromScreen`) — screen-grab signal.
- **Webcam snapshot** — single frame from the **laptop's built-in camera**, pointed at the presenter (or a prop), via `capture-webcam.ps1` (PowerShell driving ffmpeg/DirectShow; needs a portable `ffmpeg.exe` and the exact device name — get it with `list-cameras.ps1`). Never pointed at the audience or any unconsented person.
  - **Passthrough caveat:** a built-in laptop cam does not reach a guest VM automatically. VMware Workstation/VirtualBox can attach it to the guest as a USB device; **Hyper-V cannot** — in that case run the victim on the physical laptop (reset via disk image, not a snapshot). Decide this before rehearsal; it affects the whole victim-machine choice.
  - *Blue callout:* process accessing the camera device / sensitive-API use.
- **Pass-the-Cookie** — a sideloaded browser extension pulls session cookies from a lab profile; the operator imports them to hijack an already-logged-in session on a **seeded fake webapp** on the isolated network. Never a real SaaS account or real user data.
  - *Blue callout:* anomalous session/token reuse from a new device/IP → segue to MFA / session-binding / token-rotation defenses.
- **Credential dumping** — LaZagne (open-source credential-recovery tool) run locally to pull saved browser passwords from a VM **pre-seeded with dummy logins only**.
  - *Blue callout:* process reading the browser credential store.

### Closing — detection recap
Replay the defender pane's timeline and map each alert back to its act. This recap is the talk's thesis: **every step was catchable.** Leave the audience with the blue-team takeaways, not just the attack.

## Stage & AV rig

- Hypervisor host with **golden snapshots** of the victim (and attacker) images; one-command revert to reset the room between rehearsal and show or for a re-run.
- **Isolated/host-only network** connecting attacker ↔ victim ↔ fake webapp; **no uplink** to conference Wi-Fi.
- Compose the three VM screens into one projector feed: a software multi-viewer, a hardware switcher, or simply pre-arranged windows on one presenter desktop. Verify legibility from the back of the room.
- Confidence monitor for the presenters; lav mic for the Blue narrator so callouts carry.

- **Lab web server** at `10.13.37.5` serving the Act 1 artifacts (`stage.ps1`, `rustdesk.exe` portable, `RustDesk2.toml`) and the lab **RustDesk rendezvous server (hbbs)** — both on the isolated network only.

**Remote-access tooling note:** Act 1 uses RustDesk in **portable/user-level mode** as the foothold — the "attackers abuse a legitimate remote-access tool" angle, which is a real, topical TTP. The repo's `Install-RustDesk.ps1` is the *admin fleet installer* and is **not** used in the demo (it needs elevation + a service); it stays as a separate IT artifact. Placeholder key `YOUR_LAB_HBBS_PUBKEY==` in `demo-lab/RustDesk2.toml` needs the real hbbs public key before rehearsal.

## Timing (single 60-minute conference slot)

| Time | Segment |
|------|---------|
| 0:00–0:05 | Intro: who we are, rules of engagement, "everything you'll see is a sandbox" |
| 0:05–0:20 | Act 1 — USB → portable RustDesk foothold (HID cradle + remote control) |
| 0:20–0:30 | Act 2 — AV/EDR evasion (+ tamper alert) |
| 0:30–0:47 | Act 3 — post-exploitation loot round (webcam / cookies / creds) |
| 0:47–0:54 | Detection recap — the defender timeline |
| 0:54–1:00 | Q&A |

Shorter 30–45 min slot: compress Act 3 to a single loot example and trim Q&A.

## Live-demo fallback plan (public setting — assume the demo gods are hostile)

- **Pre-record every act** as short screen-capture clips at the final rehearsal. If a live step fails, cut to the clip and keep narrating — never debug on stage.
- Rehearse the full run end-to-end at least once on the exact images used on the day; snapshot immediately after a clean rehearsal and present from that snapshot.
- Keep payloads benign and self-contained so nothing depends on flaky external state.

## Ethics & disclosure for a public audience

- Payloads stay at demonstration grade (benign flag-drops, dummy creds/accounts) — show the technique and its detection, not a weaponization recipe.
- State the isolated-lab scope out loud at the top; reinforce that no real systems, accounts, or audience devices are involved.
- If the talk is recorded or streamed, the benign-payload + detection-forward framing keeps the published version defensible and educational.

## Open decisions

- [ ] **Lab hbbs public key** — fill `YOUR_LAB_HBBS_PUBKEY==` in `demo-lab/RustDesk2.toml` once the rendezvous server is stood up (IP is set to `10.13.37.5`).
- [ ] **One presenter or two** (Red + Blue) — drives the mic/stage setup.
- [ ] **Slot length** confirmed (60 min assumed above).
