# ZIP Single-Entry Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Return the contents of the ZIP archive's only regular file without deriving its name or format from the ZIP filename.

**Architecture:** Unzip each archive into an `extracted` directory inside the download's existing UUID-scoped temporary directory. A Foundation-only helper recursively requires exactly one regular file, then `LyricsFileDownloader` reads that file, writes its bytes to the existing URL-derived cache key, and preserves the public delegate API and cleanup behavior.

**Tech Stack:** Swift 5, Foundation, Zip 2.1.2, XCTest

---

### Task 1: Specify Unique Extracted File Selection

**Files:**
- Create: `AgoraLyricsScore/Class/Downloader/LyricsArchiveContent.swift`
- Create: `AgoraLyricsScore/Tests/TestDownload/TestLyricsArchiveContent.swift`
- Modify: `scripts/tests/DownloadTemporaryFileBehavior.swift`

- [x] **Step 1: Write failing tests for an arbitrarily named single file**

Add tests that create an extraction directory containing one regular file named `arbitrary.payload` and assert that `LyricsArchiveContent.onlyRegularFile(in:)` returns that URL. Also cover a hidden filename, a nested file, zero files, and multiple files.

- [x] **Step 2: Run tests and verify the missing helper fails compilation**

Run:

```bash
swiftc scripts/tests/DownloadTemporaryFileBehavior.swift AgoraLyricsScore/Class/Downloader/DownloadTemporaryFile.swift AgoraLyricsScore/Class/Downloader/Extentions.swift AgoraLyricsScore/Class/Downloader/LyricsArchiveContent.swift -o /tmp/DownloadTemporaryFileBehavior
```

Expected: compilation fails because `LyricsArchiveContent.swift` does not exist or the symbol is undefined.

- [x] **Step 3: Implement the Foundation-only selector**

Create `LyricsArchiveContent.onlyRegularFile(in:)` using `FileManager.enumerator` and `.isRegularFileKey`. Return the only regular file independent of its filename, extension, hidden status, or nesting depth; throw a descriptive error unless the count is exactly one.

- [x] **Step 4: Run the focused behavior test**

Run the `swiftc` command above followed by `/tmp/DownloadTemporaryFileBehavior`.

Expected: `DownloadTemporaryFile behavior tests passed`.

### Task 2: Consume and Cache the Unique File

**Files:**
- Modify: `AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift:119-242`
- Modify: `AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift`

- [x] **Step 1: Add lifecycle assertions for URL-derived cache naming**

Cover a ZIP request with query parameters and document that the cache key remains `<request-basename>.xml`, regardless of the extracted entry's filename or contents.

- [x] **Step 2: Pass the request cache key into the unzip path**

Change `unzip(filePath:requestId:)` and `_unzip(filePath:requestId:)` to also accept `cacheFileName`, computed from `url.lyricsCacheFileName` in `_startDownload`.

- [x] **Step 3: Replace filename derivation with isolated extraction**

Create `<download UUID>/extracted`, unzip there, obtain the sole regular file through `LyricsArchiveContent`, read its bytes, and atomically write those bytes to `String.cacheFolderPath()/cacheFileName`. Do not inspect `pathExtension`.

- [x] **Step 4: Preserve completion and cleanup semantics**

On success, remove the active request, resume queued work, and invoke completion with the extracted bytes. On extraction, selection, read, or cache-write failure, return the existing `.unzipFail`; the existing `defer` must remove the ZIP and extraction directory.

### Task 3: Verify the Download Module

**Files:**
- Verify all files changed above

- [x] **Step 1: Run standalone behavior tests**

Run the download temporary-file and downloader-manager scripts with `swiftc`; expect both executables to print their pass messages.

- [x] **Step 2: Run available Xcode build/tests**

Run `xcodebuild` for the available Demo workspace/scheme with code signing disabled. If the workspace lacks installed Pods or a test scheme, report that limitation explicitly.

- [x] **Step 3: Inspect the final diff**

Confirm no public method or delegate signature changed, no extracted filename or extension is consulted, the cache key remains request-URL-derived, and all temporary artifacts are cleaned on both success and failure.

### Task 4: Log ZIP Processing Failures

**Files:**
- Modify: `AgoraLyricsScore/Class/Downloader/LyricsArchiveContent.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift:221-274`
- Modify: `AgoraLyricsScore/Tests/TestDownload/TestLyricsArchiveContent.swift`
- Modify: `scripts/tests/DownloadTemporaryFileBehavior.swift`

- [x] **Step 1: Add a failing test for structured failure context**

Require failure descriptions to include the request ID, processing step, archive path, and underlying error description.

- [x] **Step 2: Add processing stages and failure description formatting**

Represent extraction-directory creation, archive extraction, unique-file selection, lyric-file reading, cache-directory creation, and cache writing as explicit stages.

- [x] **Step 3: Log every thrown ZIP processing failure**

Set the current stage before each throwing operation and emit one `Log.error` entry from the shared catch block before returning the existing `.unzipFail` callback.

- [x] **Step 4: Run the focused behavior test**

Compile with warnings treated as errors and confirm `DownloadTemporaryFile behavior tests passed`.

### Task 5: Complete Download and Business Error Logging

**Files:**
- Create: `AgoraLyricsScore/Class/Downloader/DownloadedLyricsFile.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/Downloader.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/DownloaderManager.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/FileCache.swift`
- Modify: `AgoraLyricsScore/Class/Other/{XmlParser,LrcParser,KrcParser}.swift`
- Modify: `Demo/Demo/VC/{DownloadVC,HostVC,MiniSizeVC,QiangChangVC,AudienceVC}.swift`
- Modify: `Demo/Demo/VC/MainVC/MainTestVC.swift`
- Modify: `AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift`
- Modify: `scripts/tests/DownloadTemporaryFileBehavior.swift`

- [x] **Step 1: Reproduce downloaded-file read and cache outcomes with failing tests**

Cover successful read/cache, unreadable source failure, and non-fatal cache-write failure.

- [x] **Step 2: Isolate downloaded-file consumption**

Read the source exactly once, return cache failures for logging without discarding valid downloaded data, and throw source-read failures.

- [x] **Step 3: Fix LRC request lifecycle and SDK logging**

Ensure every LRC terminal path removes request state, resumes queued work, logs its error context, and invokes completion exactly once. Log invalid URLs, cache-read failures, transport write failures, network failures, and owner-release cleanup paths.

- [x] **Step 4: Make business completion handling safe and observable**

Replace forced lyric-model unwraps with guarded parsing and log request IDs, complete download errors, and parse failures in every Demo downloader delegate.

- [x] **Step 5: Add parser failure logs**

Log missing XML song content, empty LRC parse results, regex construction failure, and invalid KRC UTF-8 instead of returning silently or crashing.
