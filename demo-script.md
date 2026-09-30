# Hackoween 2026 — Spoken Script: Intro & Recap

Presenter-facing speaking notes for the main-stage demonstration. Two voices:
**RED** (the operator running the attack) and **BLUE** (the defender narrating detections).
Stage directions in *[italics]*. Time each block against the run-of-show in `hackoween-2026-plan.md`.

---

## INTRO (~5 min · 0:00–0:05)

*[Screen shows the three panes dark or on a title card. RED and BLUE both on stage.]*

**RED:** Happy Hackoween, everybody. Welcome. Over the next hour you're going to watch one computer get completely taken over — from the moment someone walks up and plugs in a USB stick, all the way to the attacker reading its saved passwords and looking through its webcam.

**BLUE:** And you're going to watch me catch every single step of it. That's the deal tonight. My friend here does something nasty, and I show you the exact alarm it sets off on the defender's screen. Attack, then detection. Every time.

**RED:** So first, the boring-but-important part — because we mean it.

*[Gesture to the screen / point out the three panes.]*

**RED:** Everything you see tonight is a lab. This is isolated infrastructure that exists only for this talk. There is one victim machine, and it's a virtual machine we built to be broken into. It is not connected to the conference network. It is not connected to the internet. It has no real accounts, no real data — the passwords it "leaks" are ones we planted this morning.

**BLUE:** Nothing we do touches anything in this room. We are not on the Wi-Fi. Your phones, your laptops — completely out of scope, nothing we run can reach them. You are here to watch, not to volunteer a device. Please keep it that way.

**RED:** And what we're showing you is the *shape* of each attack and how it gets noticed — not a copy-paste recipe to go weaponize. The payloads are deliberately harmless. When our malware "detonates," it writes a little Halloween message to a file. That's it. The technique is real; the teeth are pulled on purpose.

**BLUE:** The reason we do it this way is that all of this is genuinely catchable. None of tonight is magic. Every step leaves a mark, and by the end you'll be able to name the mark.

**RED:** Here's the map for the hour. *[Walk the audience through the panes.]* Left screen is my view — the attacker's console. Middle is the victim's desktop, what the poor machine sees happening to it. And the right screen is Blue's world — the security alerts, the defender's dashboard.

**BLUE:** Watch the right screen. When it lights up, that's the moment a real security team would get paged.

**RED:** Three acts. Act one — I get in *and* I get control, with nothing but a USB device and ten seconds of physical access. No password, no admin rights. Act two, I try to blind the security tools. And act three, I help myself to everything — the webcam, the browser session, the saved passwords.

**BLUE:** And after all four, we'll rewind the whole thing and walk the timeline of alarms it generated — so you leave with the defender's playbook, not just the attacker's.

**RED:** Lights down, spooky music optional. Let's get compromised.

*[Transition to Act 1.]*

---

## RECAP (~7 min · 0:45–0:52)

*[RED steps back. BLUE takes the defender pane and scrolls its timeline from the top.]*

**BLUE:** Okay. Take a breath. In about forty minutes we watched a machine go from perfectly healthy to completely owned. Now I want to rewind — because I promised you every step of that was visible, and I want to prove it. This is the defender's timeline. Let's walk it.

**BLUE:** *[Point to the first entries.]* **Act one — the USB and the foothold.** Watch how much showed up from one plugged-in device. First, a keyboard "typed" a command faster and more perfectly than any human hand can — a brand-new keyboard that instantly launches PowerShell is not a person, it's a signal. Then that PowerShell reached out to a machine we've never seen and *ran whatever it sent back* — the download-and-run pattern, right here in the script logs. And notice what it did **not** need: no admin, no password prompt. It just started a remote-control tool running out of a temp folder — an unexpected program in a user directory — and that tool started phoning home on a steady rhythm. Count them: inhuman keystrokes, a download-and-run cradle, a remote-access binary in the wrong place, and beaconing to a stranger. Four marks, and the attacker never once needed to be an administrator.

**BLUE:** *[Next entry — emphasize.]* **Act two — this is my favorite.** When Red tried to switch off the security tools, it didn't go quiet. It got *loud.* Right here — tamper-protection alert. This is the big lesson of the night: turning off the alarm *is* an alarm. Attackers trying to blind you is one of the clearest signals you will ever get.

**BLUE:** *[Final cluster.]* **Act three — the loot.** A run of marks, close together. Something grabbed a picture of the whole screen. Something reached for the camera. Something replayed a login session from a brand-new place — the same account, suddenly active from somewhere it had never been. And something cracked open the browser's password vault and read it. *[Point to each.]* Screen capture, camera access, anomalous session reuse, credential-store read. Four thefts, four alerts.

**BLUE:** So — count them with me. *[Gesture down the list.]* Nine distinct moments where a defender who was watching this screen would have known. The attack was fast, it needed no special privileges — and it was never quiet.

**RED:** *[Stepping back in.]* And that's the part I want you to take home. My job looks impressive on the left screen. But everything I did showed up on the right one. The gap between those two screens — that's where security teams win or lose.

**BLUE:** A few things you can actually do with this. If a keyboard shows up and immediately starts running commands — or a machine starts beaconing to somewhere new on a regular beat — that's worth an alarm; that was all Act one. Watch for remote-access tools running out of temp and user folders where they don't belong. Turn tamper protection *on* and alert on it, because attackers will trip it for you — Act two. And bind sessions and rotate tokens, so a stolen cookie stops working the second it leaves the building — Act three.

**RED:** None of tonight required a movie-hacker genius. It required physical access, a click, and a defender who wasn't looking. Be the defender who's looking.

**BLUE:** That's Hackoween. Thanks for watching us break things responsibly. *[Beat.]* Questions?

*[Transition to Q&A.]*

---

### Delivery notes
- **Pace the intro.** The scope/ethics lines are the ones the audience (and any recording) most needs to hear clearly — don't rush them.
- **The recap is the payoff.** Slow down on Act 2's tamper alert; it's the single most memorable takeaway.
- If running a **single presenter**, keep both voices but drop the RED/BLUE handoffs — read it straight through, pausing to switch panes where BLUE speaks.
- If an act **failed live and you cut to a pre-recorded clip**, the recap still works unchanged — the alerts are on the timeline either way. Don't apologize for the cut; just narrate.
- **Q&A landmine to pre-empt:** if someone asks "how do I do the USB part," pivot to detection — "the interesting question isn't how to send the keystrokes, it's how you'd have caught it," and point back at Act 1's signal.
