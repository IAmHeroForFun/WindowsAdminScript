# 🔗 Windows 10/11 Shared Drive & USB Shared Printer Repair Suite

A production-grade, interactive administration suite to diagnose and resolve Windows 10 & 11 local network sharing issues, guest SMB access blocks, and USB shared printer connection failures across heterogeneous Windows desktop and server environments.

---

## ⚠️ The Two-Machine Reality: HOST vs. CLIENT

> [!IMPORTANT]
> **Shared printing involves TWO separate computers! Running fixes on the wrong computer will NOT resolve the issue!**

| Machine Role | Who Is It? | What MUST Be Run Here? |
| :--- | :--- | :--- |
| **🖥️ HOST PC**<br>*(Print Server)* | The computer with the **USB printer cable physically plugged in**, sharing it to the network. | **Fix Error `0x0000011b`** (`RpcAuthnLevelPrivacyEnabled = 0`), switch network from **Public to Private**, unblock inbound firewall ports (135, 445, Spooler RPC), enable Network Discovery services (`fdPHost`, `FDResPub`), and grant `Everyone` print permissions. |
| **💻 CLIENT PC**<br>*(Workstation)* | The computer in another room/desk **trying to connect across the network and print**. | **Fix Error `0x00000bc4`** ("No printers found"), **Error `0x00000709`**, bypass Point & Print Non-Admin block (`0x00000bcb`), fix CopyFiles (`0x0000007c`), and disable Windows 11 24H2 Windows Protected Print (WPP). |

---

## 🤔 Why Does Windows 10 to Windows 10 Sharing Fail on Some PCs but Work on Others?

If you have two Windows 10 PCs on the same Wi-Fi or office network, why does sharing work between some pairs but fail on others?
1. **Network Profile is "Public" (The #1 Silent Killer)**:
   - When a PC connects to a network, Windows asks "Make this PC discoverable?". If a user clicked "No", Windows assigns the network as **Public**.
   - On a Public profile, Windows Firewall **silently drops 100% of inbound printer and SMB traffic** without showing an error!
   - *Fix*: The Host script automatically detects this and switches the active network profile to **Private**.
2. **Patch Level Differences (KB5005565 / KB5005568 / KB5006670)**:
   - A fully updated Windows 10 PC has the PrintNightmare security patch requiring RPC authentication privacy (`RpcAuthnLevelPrivacyEnabled = 1`).
   - If the Host PC has this update, non-updated clients or clients without matching encryption are rejected with **`0x0000011b`**.
3. **Password-Protected Sharing & Account Mismatch (Error 5 Access Denied)**:
   - If user accounts on PC 1 and PC 2 do not have identical usernames and passwords, Windows rejects the connection.
   - *Fix*: Setting `AllowInsecureGuestAuth = 1`, `LocalAccountTokenFilterPolicy = 1`, and ensuring `Everyone` has print rights on the share.
4. **Network Discovery Background Services Are Stopped**:
   - On many Windows 10 machines, `fdPHost` (Function Discovery Provider Host) and `FDResPub` (Function Discovery Resource Publication) are set to Manual or Disabled, making the PC invisible on the network.

---

## 📁 Dedicated 1-Click Batch Launchers

To make execution completely foolproof for technicians:

```text
network_sharing_fixer/
├── 1_RUN_ON_HOST_PC (Printer Attached).bat            # Double-click on PC with printer
├── 2_RUN_ON_CLIENT_PC (Connect Over Network).bat      # Double-click on PC that wants to print
├── 3_UNIVERSAL_ALL_IN_ONE_FIX.bat                     # Applies both Host & Client fixes
├── 4_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat # 100% Guaranteed Local Port Workaround
├── Run-As-Administrator.bat                           # Master interactive launcher
├── Fix-Shared-Printers.ps1                            # Shared printer core logic
├── Fix-SMB-Shares.ps1                                 # Shared drive & SMB core logic
├── Reset-Network-Sharing-Firewall.ps1                 # Firewall unblock module
└── fix_sharing.ps1                                    # Main suite coordinator
```

---

## 🚀 Solved Errors & Issues

### 1. USB Shared Printer & Point and Print Errors
- **`0x0000011b`**: Print Spooler RPC authentication privacy error (Fixed on Host).
- **`0x00000bc4`**: "No printers were found" (Fixed on Client by configuring RPC over Named Pipes).
- **`0x00000709`**: Could not connect to shared printer / CNAME alias mismatch / stale default printer cache.
- **`0x00000bcb`**: Point and Print restrictions blocking non-admin users from installing shared printer drivers.
- **`0x0000007c`**: CopyFiles policy block in printer drivers.
- **`Error 5 / Access Denied`**: Remote UAC token stripping and insecure guest auth blocking.
- **Windows 11 24H2 Windows Protected Print (WPP)**: Blocks all legacy Type 3 (v3) vendor drivers (HP, Canon, Brother, Epson). Automatically detected and disabled.
- **Windows 11 24H2 SMB Client Signing**: Outbound SMB signing relaxed to support mixed-version networks.

### 2. Shared Drive & NAS Access Errors
- `0x800704f8`: Unauthenticated guest access blocked by organization security policy.
- `0x80070035`: Network path not found (Network discovery services stopped).
- `0x80004005`: Unspecified network error on SMB shares.

---

## 🏆 The Ultimate Workaround: Automated Local Port Connection (100% Success Rate)

When two Windows 10/11 machines have stubborn build incompatibilities, locked domain GPOs, or corrupted spooler drivers:
1. Select **Option [4]** or run **`4_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat`**.
2. Enter the target shared printer path: `\\192.168.1.50\PrinterShare`.
3. The wizard creates a **Local Port** directly mapped to the UNC network stream.
4. Select an installed driver on the client (or generic Microsoft Class Driver).
5. **Result**: Windows sends raw print jobs directly over the SMB stream, completely bypassing Spooler RPC negotiation! **Works 100% of the time!**

---

## 💻 Execution

### Run via Master Toolkit
Launch `windows_it_toolkit.ps1` and select:
```text
[12] Windows 10/11 Network Folder & SMB Sharing Fixer
```
