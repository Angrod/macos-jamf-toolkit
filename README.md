# macOS & Jamf Pro Automation Toolkit

Shell scripts, extension attributes and configuration profiles for managing a Mac fleet with **Jamf Pro**. They come from day-to-day Mac administration and have been cleaned up, generalized and documented so they can be dropped into any Jamf Pro environment.

> ⚠️ **Disclaimer:** these scripts change system settings, remove software and handle credentials. **Test every script on a non-production Mac (a VM or a test device in a test Smart Group) before scoping it to real users.** They are provided as-is under the [MIT License](LICENSE), with no warranty.

---

## What this repository demonstrates

| Competency | Where to look |
|---|---|
| **macOS administration**: user and group management, SecureToken / Bootstrap Token, TCC/PPPC, launchd, CUPS, networking | [`provisioning-workflows/`](provisioning-workflows), [`demote-local-admins.sh`](utilities-and-maintenance/demote-local-admins.sh), [`pppc-*.mobileconfig`](jamf/configuration-profiles) |
| **Jamf Pro automation**: parameterized policy scripts, extension attributes, custom triggers, Jamf Pro API (bearer token and OAuth client credentials) | [`jamf/policy-scripts/`](jamf/policy-scripts), [`jamf/extension-attributes/`](jamf/extension-attributes), [`jamf-api-bearer-token.sh`](utilities-and-maintenance/jamf-api-bearer-token.sh) |
| **Zero-touch deployment**: naming, user assignment, baseline apps and token escrow during Automated Device Enrollment | [Zero-touch provisioning](#zero-touch-provisioning) |
| **Security & compliance**: least privilege, Bootstrap Token escrow, iCloud restrictions, firewall lockdown, EDR/vulnerability agent deployment | [Least-privilege admin rights](#least-privilege-admin-rights), [`restrict-icloud-services.mobileconfig`](jamf/configuration-profiles/restrict-icloud-services.mobileconfig) |
| **Self-healing remediation**: inventory detects drift, a Smart Group scopes the fix, a script repairs it and verifies the result | [Self-healing workflows](#featured-workflows) |

**Engineering conventions used throughout**
- A standard header in every file: Title, Description, Usage/Context, Jamf Parameters, Requirements, Author and Credits.
- Every policy script validates its inputs, logs with timestamps, exits 0 on success or 1 on failure, and is **safe to run again** (it skips work that's already done).
- No secrets in code: credentials come from Jamf script parameters or environment variables, and scripts refuse to run with `[INSERT_…]` placeholder values.
- The console user is found with `scutil`, not by parsing `ls`/`who`; user-facing apps are launched in the user's own context, never as root.
- Linted with ShellCheck (0 findings); every Bash/zsh script passes `bash -n` / `zsh -n` and every profile parses as a valid plist.

---

## Featured workflows

These show how the pieces fit together: inventory (an extension attribute) feeds a Smart Group, which scopes a policy, which fixes the problem and confirms the fix.

### Zero-touch provisioning
Runs from enrollment policies after Automated Device Enrollment:
1. [`set-computer-name.sh`](provisioning-workflows/set-computer-name.sh) sets a consistent, DNS-safe ComputerName, HostName and LocalHostName, with an optional site prefix.
2. [`set-jamf-end-username.sh`](provisioning-workflows/set-jamf-end-username.sh) assigns the Mac to its user in Jamf Pro so scoping and reporting work.
3. [`install-if-missing.sh`](provisioning-workflows/install-if-missing.sh) brings up the baseline app set; one script is reused for every app.
4. [`ensure-management-account.sh`](provisioning-workflows/ensure-management-account.sh), [`enable-securetoken-local-admin.zsh`](provisioning-workflows/enable-securetoken-local-admin.zsh) and [`escrow-bootstrap-token.zsh`](provisioning-workflows/escrow-bootstrap-token.zsh) ensure the IT account exists, holds a SecureToken, and that MDM holds the Bootstrap Token.

### Self-healing: Bootstrap Token
[`bootstrap-token-status.zsh`](jamf/extension-attributes/bootstrap-token-status.zsh) (EA) → Smart Group *"Bootstrap Token not escrowed"* → [`escrow-bootstrap-token.zsh`](provisioning-workflows/escrow-bootstrap-token.zsh) → the next inventory update confirms "Escrowed".

### Self-healing: restart reminders
[`uptime-days.sh`](jamf/extension-attributes/uptime-days.sh) (EA) → [`uptime-check.sh`](utilities-and-maintenance/uptime-check.sh) runs daily → calls [`uptime-restart-prompt.sh`](utilities-and-maintenance/uptime-restart-prompt.sh), a jamfHelper prompt with delay options, once a Mac has been up longer than the threshold.

### Least-privilege admin rights
[`admin-group-membership.sh`](jamf/extension-attributes/admin-group-membership.sh) (EA) shows who is an admin → [`demote-local-admins.sh`](utilities-and-maintenance/demote-local-admins.sh) removes admin rights from everyone except named IT accounts. It refuses to run unless one of those accounts is still an admin, so a Mac is never left without an administrator. [`promote-current-user-to-admin.sh`](utilities-and-maintenance/promote-current-user-to-admin.sh) handles approved exceptions.

### Clean app lifecycle
Install: [`install-app-from-cached-dmg.sh`](jamf/policy-scripts/install-app-from-cached-dmg.sh), [`install-update-slack.sh`](jamf/policy-scripts/install-update-slack.sh), [`install-update-zoom.sh`](jamf/policy-scripts/install-update-zoom.sh)
→ hand ownership to the user so self-updaters work: [`set-app-ownership.sh`](jamf/policy-scripts/set-app-ownership.sh)
→ remove cleanly: [`remove-application.sh`](jamf/policy-scripts/remove-application.sh), [`uninstall-microsoft-office.sh`](jamf/policy-scripts/uninstall-microsoft-office.sh), [`uninstall-adobe-creative-cloud.zsh`](jamf/policy-scripts/uninstall-adobe-creative-cloud.zsh).

---

## Repository layout

```
.
├── jamf/
│   ├── extension-attributes/     # inventory data collected at every recon (21)
│   ├── policy-scripts/           # deployment, remediation and Self Service scripts (28)
│   └── configuration-profiles/   # .mobileconfig / custom-settings plists (5)
├── provisioning-workflows/       # enrollment and zero-touch setup (7)
├── utilities-and-maintenance/    # local admin management, clean-up, Jamf API tooling (9)
├── LICENSE
└── README.md
```

---

## Script catalog

### `jamf/extension-attributes/`
Upload each as a Jamf Pro extension attribute with **Input Type: Script** and the data type shown.

| Script | What it reports / problem it solves | Data type |
|---|---|---|
| [admin-group-membership.sh](jamf/extension-attributes/admin-group-membership.sh) | Members of the local `admin` group and nested groups, to spot unexpected administrators. | String |
| [applecare-warranty-expiration.sh](jamf/extension-attributes/applecare-warranty-expiration.sh) | AppleCare / warranty end date cached by macOS, for hardware-refresh planning. | Date |
| [battery-condition.sh](jamf/extension-attributes/battery-condition.sh) | Battery health ("Normal", "Service Recommended"), for proactive replacements. | String |
| [battery-cycle-count.sh](jamf/extension-attributes/battery-cycle-count.sh) | Battery cycle count (blank on desktops). | Integer |
| [bootstrap-token-status.zsh](jamf/extension-attributes/bootstrap-token-status.zsh) | Whether the Bootstrap Token is escrowed to MDM. | String |
| [box-drive-version.sh](jamf/extension-attributes/box-drive-version.sh) | Installed Box Drive version, for patch reporting. | String |
| [chip-architecture.sh](jamf/extension-attributes/chip-architecture.sh) | Apple Silicon vs Intel (correct even under Rosetta 2), for architecture-specific scoping. | String |
| [disk-free-space.sh](jamf/extension-attributes/disk-free-space.sh) | Free space on the boot volume, to catch Macs too full to update. | String |
| [find-my-mac-status.sh](jamf/extension-attributes/find-my-mac-status.sh) | Whether Find My Mac is on (Activation Lock risk before redeploying). | String |
| [firefox-version.sh](jamf/extension-attributes/firefox-version.sh) | Release-channel Firefox version. | String |
| [gpu-model.sh](jamf/extension-attributes/gpu-model.sh) | GPU model(s), for hardware and software compatibility checks. | String |
| [home-folder-size.sh](jamf/extension-attributes/home-folder-size.sh) | Per-folder home directory sizes, cached by a policy so recon stays fast. | String |
| [installed-configuration-profiles.sh](jamf/extension-attributes/installed-configuration-profiles.sh) | Names of every installed profile, to audit configuration drift. | String |
| [last-reboot.sh](jamf/extension-attributes/last-reboot.sh) | Last boot time. | Date |
| [local-admin-account-status.zsh](jamf/extension-attributes/local-admin-account-status.zsh) | Whether the IT admin account exists, is hidden, and holds a SecureToken. | String |
| [machine-whereabouts.xml](jamf/extension-attributes/machine-whereabouts.xml) | Pop-up menu EA tracking where a Mac is in its lifecycle (Classic API XML). | Pop-up menu |
| [microsoft-autoupdate-present.sh](jamf/extension-attributes/microsoft-autoupdate-present.sh) | Whether Microsoft AutoUpdate is installed. | String |
| [outlook-profile-size.sh](jamf/extension-attributes/outlook-profile-size.sh) | Outlook profile size, flagging profiles over 5 GB before they cause problems. | String |
| [preferred-wifi-networks.sh](jamf/extension-attributes/preferred-wifi-networks.sh) | Saved Wi-Fi networks, to find guest or personal SSIDs on corporate Macs. | String |
| [softwareupdate-schedule.sh](jamf/extension-attributes/softwareupdate-schedule.sh) | Whether automatic update checking is on. | String |
| [uptime-days.sh](jamf/extension-attributes/uptime-days.sh) | Days since the last boot; drives restart reminders. | Integer |

### `jamf/policy-scripts/`

| Script | Problem it solves | Parameters |
|---|---|---|
| [allow-standard-users-add-printers.sh](jamf/policy-scripts/allow-standard-users-add-printers.sh) | Lets standard users add printers without an admin password. | $4 group |
| [clear-office-cache.sh](jamf/policy-scripts/clear-office-cache.sh) | Self Service fix for Office add-ins that won't load or apps that hang. | — |
| [disable-printer-sharing.sh](jamf/policy-scripts/disable-printer-sharing.sh) | Turns off printer sharing (CIS benchmark item) and confirms it. | — |
| [enable-ssh-for-admin.sh](jamf/policy-scripts/enable-ssh-for-admin.sh) | Enables SSH, restricted to a single admin account. | $4 account |
| [install-app-from-cached-dmg.sh](jamf/policy-scripts/install-app-from-cached-dmg.sh) | Installs a `.app` or `.pkg` from any cached DMG, regardless of its volume name. | $4 DMG, $5 item, $6 keep |
| [install-crowdstrike-falcon.sh](jamf/policy-scripts/install-crowdstrike-falcon.sh) | Installs and licenses the Falcon sensor, then checks it reports in. | $4 CID, $5 package |
| [install-nessus-agent.sh](jamf/policy-scripts/install-nessus-agent.sh) | Installs and links the Tenable Nessus Agent with a per-device name. | $4–$8 |
| [install-rapid7-agent.sh](jamf/policy-scripts/install-rapid7-agent.sh) | Installs the right Rapid7 Insight Agent build for the CPU; skips Macs that already have it. | $4 token, $5 folder |
| [install-update-slack.sh](jamf/policy-scripts/install-update-slack.sh) | Keeps Slack current from Slack's release feed without interrupting users. | $4 `kill` |
| [install-update-zoom.sh](jamf/policy-scripts/install-update-zoom.sh) | Installs or updates Zoom from its IT package, with optional checksum check and forced update. | $4 SHA-256, $5 `kill` |
| [jamfhelper-alert.sh](jamf/policy-scripts/jamfhelper-alert.sh) | Reusable jamfHelper message window for any policy. | $4–$7 |
| [logout-current-user.sh](jamf/policy-scripts/logout-current-user.sh) | Ends the user's session (e.g. to finish a login-window change). | — |
| [reenable-printer-queues.sh](jamf/policy-scripts/reenable-printer-queues.sh) | One-click fix for "printer is paused" tickets. | — |
| [remove-application.sh](jamf/policy-scripts/remove-application.sh) | Generic app removal (one script instead of one per app). | $4 app, $5 process |
| [remove-garageband-imovie.sh](jamf/policy-scripts/remove-garageband-imovie.sh) | Reclaims several GB used by preinstalled creative apps. | — |
| [remove-microsoft-autoupdate.sh](jamf/policy-scripts/remove-microsoft-autoupdate.sh) | Removes MAU where Office is patched centrally instead. | — |
| [remove-preferred-wifi-network.sh](jamf/policy-scripts/remove-preferred-wifi-network.sh) | Stops laptops auto-joining guest or IoT SSIDs. | $4–$6 SSIDs |
| [remove-quarantine-attribute.sh](jamf/policy-scripts/remove-quarantine-attribute.sh) | Removes the "downloaded from the Internet" prompt for vetted, IT-deployed apps. | $4 app |
| [set-app-ownership.sh](jamf/policy-scripts/set-app-ownership.sh) | Gives an app to the user so its built-in updater works for standard users. | $4 app, $5 open |
| [set-firewall-block-all.sh](jamf/policy-scripts/set-firewall-block-all.sh) | Incident-response firewall lockdown and undo. | $4 on/off |
| [uninstall-adobe-creative-cloud.zsh](jamf/policy-scripts/uninstall-adobe-creative-cloud.zsh) | Removes every Creative Cloud app, Acrobat DC and the CC desktop app. | — |
| [uninstall-crashplan.sh](jamf/policy-scripts/uninstall-crashplan.sh) | Complete CrashPlan removal (vendor uninstaller, launchd items, leftover files). | — |
| [uninstall-cylance.sh](jamf/policy-scripts/uninstall-cylance.sh) | Silent CylancePROTECT removal during an EDR migration. | $4 password |
| [uninstall-jamf-connect.sh](jamf/policy-scripts/uninstall-jamf-connect.sh) | Removes Jamf Connect without leaving a broken login window. | — |
| [uninstall-microsoft-office.sh](jamf/policy-scripts/uninstall-microsoft-office.sh) | Office-only uninstall or reset in three modes; Edge, Teams, OneDrive and Defender are untouched. | $4 mode |
| [uninstall-nessus-agent.sh](jamf/policy-scripts/uninstall-nessus-agent.sh) | Unlinks and removes the Nessus Agent. | — |
| [unlock-printing-datetime-prefs.sh](jamf/policy-scripts/unlock-printing-datetime-prefs.sh) | Lets standard users change printer and time-zone settings. | — |
| [write-home-folder-size.sh](jamf/policy-scripts/write-home-folder-size.sh) | Caches home-folder sizes for the companion EA. | $4 plist domain |

### `jamf/configuration-profiles/`

| Profile | Purpose |
|---|---|
| [restrict-icloud-services.mobileconfig](jamf/configuration-profiles/restrict-icloud-services.mobileconfig) | Keeps corporate data out of personal iCloud (Drive, Photos, Keychain, Find My, Private Relay…). |
| [pppc-terminal.mobileconfig](jamf/configuration-profiles/pppc-terminal.mobileconfig) | PPPC/TCC pre-approval for Terminal (IT Macs only). |
| [pppc-code42.mobileconfig](jamf/configuration-profiles/pppc-code42.mobileconfig) | PPPC/TCC pre-approval so backups can cover the whole user profile. |
| [pppc-macrorecorder.mobileconfig](jamf/configuration-profiles/pppc-macrorecorder.mobileconfig) | PPPC/TCC pre-approval for an automation app without granting admin rights. |
| [nudge-preferences.plist](jamf/configuration-profiles/nudge-preferences.plist) | [Nudge](https://github.com/macadmins/nudge) settings for update deadlines and deferrals (upload as Application & Custom Settings). |

### `provisioning-workflows/`

| Script | Problem it solves | Parameters |
|---|---|---|
| [enable-securetoken-local-admin.zsh](provisioning-workflows/enable-securetoken-local-admin.zsh) | Gives the IT admin the first SecureToken on a fresh Mac. | $4/$5 Base64 credentials |
| [ensure-management-account.sh](provisioning-workflows/ensure-management-account.sh) | Re-creates the IT account if it goes missing. | $4 account, $5 trigger |
| [escrow-bootstrap-token.zsh](provisioning-workflows/escrow-bootstrap-token.zsh) | Escrows the Bootstrap Token so MDM can manage SecureTokens and updates. | $4/$5 Base64 credentials |
| [grant-securetoken.sh](provisioning-workflows/grant-securetoken.sh) | Grants a SecureToken to an admin using an existing token holder. | $4–$7 Base64 credentials |
| [install-if-missing.sh](provisioning-workflows/install-if-missing.sh) | Reinstalls a baseline app if it has gone missing. | $4 app, $5 trigger |
| [set-computer-name.sh](provisioning-workflows/set-computer-name.sh) | Consistent, DNS-safe device names with an optional site prefix. | $4–$7 |
| [set-jamf-end-username.sh](provisioning-workflows/set-jamf-end-username.sh) | Assigns the Mac to its user in Jamf Pro. | $4 domain suffix |

### `utilities-and-maintenance/`

| Script | Problem it solves | Parameters |
|---|---|---|
| [clear-jamf-waiting-room.sh](utilities-and-maintenance/clear-jamf-waiting-room.sh) | Frees disk space taken by abandoned cached packages. | — |
| [demote-local-admins.sh](utilities-and-maintenance/demote-local-admins.sh) | Least-privilege rollout with a guard against leaving a Mac with no admin. | $4 accounts to keep |
| [jamf-api-bearer-token.sh](utilities-and-maintenance/jamf-api-bearer-token.sh) | Jamf Pro API authentication (OAuth client credentials or user account) for your own tooling. | env vars |
| [promote-current-user-to-admin.sh](utilities-and-maintenance/promote-current-user-to-admin.sh) | Grants admin rights for approved exceptions. | — |
| [remove-macos-installers.sh](utilities-and-maintenance/remove-macos-installers.sh) | Removes leftover 12 GB+ macOS installers, optionally keeping one. | $4 installer to keep |
| [reset-softwareupdate-daemon.sh](utilities-and-maintenance/reset-softwareupdate-daemon.sh) | Fixes Macs stuck on "Checking for updates". | — |
| [rotate-local-admin-password.sh](utilities-and-maintenance/rotate-local-admin-password.sh) | Rotates one or two local admin passwords and confirms the new one works. | $4–$9 |
| [uptime-check.sh](utilities-and-maintenance/uptime-check.sh) | Daily uptime check that triggers a restart reminder. | $4 days, $5 trigger |
| [uptime-restart-prompt.sh](utilities-and-maintenance/uptime-restart-prompt.sh) | User-friendly restart prompt with delay options. | $4–$6 |

---

## Using the scripts

### Jamf Pro script parameters (`$4`–`$11`)
Jamf Pro passes `$1` (mount point), `$2` (computer name) and `$3` (username) to every script. **`$4`–`$11` are yours**, and this repo uses them for anything that varies between environments:

1. Add the script in **Settings → Computer Management → Scripts**.
2. Under **Options → Parameter Labels**, copy the labels from the script's `Jamf Parameters:` header, for example `$4 = App name, with or without ".app"`.
3. In each policy's **Scripts** payload, fill in the values. One script serves many policies: `install-if-missing.sh` is reused with `Google Chrome` / `chrome`, `Slack` / `slack`, and so on.

Each header marks parameters as **[required]** or **[optional, default: …]**. A script exits 1 with a clear log message if a required parameter is empty or still holds a placeholder, so a half-configured policy fails safely instead of acting on bad data.

> **Credentials:** a few scripts take passwords as Base64-encoded parameters. Base64 is obfuscation, **not encryption**. Limit who can view those policies, and prefer Jamf's built-in LAPS and API Roles & Clients where you can.

### Placeholders (`[INSERT_…]`)
Extension attributes, configuration profiles and API XML can't receive script parameters, so they use clearly marked placeholders instead. Replace them before uploading:

| Placeholder | Where | Replace with |
|---|---|---|
| `[INSERT_ADMIN_USER]` | `local-admin-account-status.zsh` | Short name of your IT admin account |
| `[INSERT_COMPANY_NAME]` | `*.mobileconfig` (`PayloadOrganization`) | Your organization's name |
| `[INSERT_APPLE_TEAM_ID]` | `pppc-code42.mobileconfig`, `pppc-macrorecorder.mobileconfig` | The vendor's Team ID: `codesign -dr - /Applications/<App>.app` |
| `[INSERT_COMPANY_LOGO]` | `nudge-preferences.plist` | File name of your logo in `/Library/Application Support/Nudge/` |
| `[INSERT_JAMF_OBJECT_ID]` | `machine-whereabouts.xml` | `0` to create a new object (Jamf assigns the ID) |
| `[INSERT_LOCATION_1–3]` | `machine-whereabouts.xml` | Your storage / office site names |
| `com.yourcompany.app` | `home-folder-size.sh` + `write-home-folder-size.sh` | Your reverse-domain identifier (keep both in sync) |
| `https://your-instance.jamfcloud.com` | `jamf-api-bearer-token.sh`, `machine-whereabouts.xml` | Your Jamf Pro URL (the API script reads `JAMF_URL`) |

Find any that remain with:
```bash
grep -rnE '\[INSERT_[A-Z0-9_]+\]|yourcompany|your-instance' jamf provisioning-workflows utilities-and-maintenance
```

### Validating changes
```bash
bash -n script.sh            # syntax check (zsh -n for .zsh files)
shellcheck script.sh         # lint (Bash scripts)
plutil -lint profile.mobileconfig
```

---

## License and credits

Original work in this repository is released under the [MIT License](LICENSE). Some scripts build on community work, credited in their headers:

| Script | Builds on | Upstream licence |
|---|---|---|
| `uninstall-crashplan.sh` | Palantir [mac-jamf uninstaller-template](https://github.com/palantir/mac-jamf) | Apache-2.0 (original notice kept in the file) |
| `install-update-zoom.sh` | William Smith's ([talkingmoose](https://gist.github.com/talkingmoose)) Microsoft installer script | CC BY 4.0 |
| `install-update-slack.sh` | Shaquir Tannis and Jamf Nation contributors | Not stated |
| `install-nessus-agent.sh` | Caine Hörr's Nessus Agent installer | Not stated |
| `uninstall-adobe-creative-cloud.zsh` | Anthony Reimer ([maclabs.jazzace.ca](https://maclabs.jazzace.ca/2020/11/01/unistalling-adobe-apps.html)) and Adobe docs | Not stated |
| `uptime-check.sh`, `uptime-restart-prompt.sh` | "Adam T." and the Jamf Nation uptime discussion | Not stated |
| `jamf-api-bearer-token.sh` | Jamf developer documentation examples | — |

Thanks also to the wider Mac admin community whose tools shaped how I work: [Rich Trouton](https://github.com/rtrouton/rtrouton_scripts), [Elliot Jordan](https://github.com/homebysix), [macadmins/Nudge](https://github.com/macadmins/nudge), [AutoPkg](https://github.com/autopkg/autopkg) and [Jamf Nation](https://community.jamf.com).

---

*Maintained by [Angrod](https://github.com/Angrod).*
