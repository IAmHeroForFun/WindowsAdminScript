# Windows Search, Indexing & Outlook Search Repair Suite

An automated diagnostic and repair suite for Windows Search, Start Menu search indexing, and Microsoft Outlook MAPI email indexing.

## Features
- **WSearch Service Health & Reset**: Configures `WSearch` service to Automatic startup and cleanly restarts the search daemon.
- **Index Database Purge & Rebuild**: Safely stops `SearchIndexer` and deletes corrupt/bloated `Windows.edb` (>2 GB) databases to trigger clean indexing.
- **Start Menu & Search Bar UWP Re-Registration**: Re-registers Modern Windows Search & ShellExperienceHost app packages to resolve unclickable/frozen search boxes.
- **Local File Search Speed Optimization**: Disables Bing web results and Cortana consent in Start Menu search to prioritize instant local file search.
- **Outlook Email Search & MAPI Indexing Repair**:
  - Removes `PreventIndexingOutlook` GPO/Registry blocks.
  - Sets `EnableSearchIndexMapi = 1` and `DisableIndexingPST = 0`.
  - Verifies and restores `.pst` and `.ost` persistent IFilter handlers in `HKCR`.

## Direct Execution
```powershell
irm https://toolkit.omvihub.in/search | iex
```
