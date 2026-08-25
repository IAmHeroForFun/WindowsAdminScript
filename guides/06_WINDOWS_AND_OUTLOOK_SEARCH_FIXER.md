# 06. Windows Search & Indexing Repair Suite (EDB, UWP & MAPI)

## 📌 Executive Summary
The **Windows & Outlook Search Indexing Repair Suite** (`search_fixer/fix_search.ps1` & `search_fixer/Fix-Outlook-Search.ps1`) repairs damaged Windows Search indexing, unresponsive Start Menu search bars, bloated `Windows.edb` databases (>2GB), and Outlook MAPI email indexing failures ("No results found" in Outlook).

---

## 🏗️ Architecture & Script Mapping

- **Primary Master Fixer**: `search_fixer/fix_search.ps1`
- **Outlook Search Module**: `search_fixer/Fix-Outlook-Search.ps1`
- **Batch Launcher**: `search_fixer/run_search_fixer.bat`
- **Master Menu Option**: `[6]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/search | iex`

---

## 🔧 Technical Repair Actions

1. **Windows Search Service Reset**:
   - Configures `WSearch` service startup to `Automatic`.
   - Force-terminates hung `SearchIndexer.exe` processes and cleanly restarts `WSearch`.

2. **Index Database Purge & Rebuild**:
   - Target: `C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb`
   - Stops `WSearch`, terminates indexers, purges bloated `.edb` database files, and restarts `WSearch` to trigger a clean background crawl.

3. **Start Menu & Search Bar UWP Package Re-Registration**:
   - Re-registers `Microsoft.Windows.Search` and `Microsoft.Windows.ShellExperienceHost` app manifests via `Add-AppxPackage` to resolve frozen/unclickable search bars.

4. **Local Search Speed Optimization**:
   - Configures `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search`:
     - `BingSearchEnabled = 0`
     - `CortanaConsent = 0`
   - Eliminates web query latency when searching for local files in the Start Menu.

5. **Outlook Email Search & MAPI Indexing Repair**:
   - Clears `PreventIndexingOutlook` from `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`.
   - Sets `EnableSearchIndexMapi = 1` and `DisableIndexingPST = 0` in `HKCU:\Software\Microsoft\Office\<Ver>\Outlook\Search`.
   - Verifies and registers `.pst` and `.ost` persistent IFilter handlers in `HKCR`.
   - Triggers fresh indexing of Outlook mailboxes and PST archives.
