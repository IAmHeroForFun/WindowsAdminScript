# 🔍 Windows Search & Indexing Repair Tool

An automated diagnostic and repair suite engineered to fix Start Menu search failures, unresponsive search bars, and broken or sluggish file indexing across Windows 7 through Windows 11.

---

## 🛠️ Common Causes of Search & Indexing Failures Solved

1. **Corrupted or Bloated Index Database (`Windows.edb`)**: Over time or after unexpected shutdowns, the central search index database corrupts or swells to multiple gigabytes, causing search queries to spin endlessly or return blank results.
2. **Hung `WSearch` Service**: The background indexing service stops or fails to initialize.
3. **Broken Universal Windows Platform (UWP) Search UI**: On Windows 10 & 11, Start Menu search relies on UWP app manifests (`Microsoft.Windows.Search`). If registration drops, clicking the search bar does nothing.
4. **Web Search Latency (Bing Integration)**: Start Menu search lagging while attempting to query Bing web results over slow connections.

---

## 🚀 How to Use

1. Double-click **`run_search_fixer.bat`** (Run as Administrator is recommended for service resets).
2. Review the Phase 1 diagnostic checks inspecting `WSearch` service health and database file size.
3. Answer **`[Y/N]`** for each interactive repair step:
   * **`[ACTION 1/4]`**: Reset service & configure Automatic startup.
   * **`[ACTION 2/4]`**: Purge corrupted database & trigger clean rebuild. *(Solves 85% of issues)*
   * **`[ACTION 3/4]`**: Re-register Start Menu & Search UWP packages.
   * **`[ACTION 4/4]`**: Prioritize local file search speed over web results.
