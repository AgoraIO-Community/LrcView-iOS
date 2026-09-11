# Download Temporary File Safety Design

## Context

`Downloader` currently opens the response file with `OutputStream(url:append: true)` in a shared temporary download directory. A completed ZIP is not removed after extraction, and a later download with the same suggested filename appends a new archive to the existing file. Failed and cancelled downloads can also leave partial files. In addition, ZIP requests look for a cached `.zip` even though extraction produces an `.xml` file.

The downloader performs complete HTTP GET requests and does not implement HTTP Range requests. Partial files therefore cannot be resumed safely and must not be reused.

## Goals

- Start every download from an empty file.
- Isolate downloads that resolve to the same suggested filename.
- Remove temporary data after success, failure, or cancellation.
- Allow a failed URL to be retried with the same manager instance.
- Resolve ZIP requests to their extracted XML cache entry.
- Preserve the public `LyricsFileDownloader` API and callback behavior.

## Non-Goals

- Add resumable downloads.
- Change cache retention limits or public error types.
- Replace the current URL session architecture with `URLSessionDownloadTask`.
- Persist ZIP files between app launches.

## Design

### Temporary Storage

Use `FileManager.default.temporaryDirectory` as the iOS application-scoped temporary root. Each `Downloader` creates a unique task directory beneath `LyricDownloadFiles` and writes the response's suggested filename inside it:

```
<temporaryDirectory>/LyricDownloadFiles/<UUID>/<suggestedFilename>
```

The output stream uses `append: false`. The unique directory prevents separate URLs with identical response filenames from writing to the same file.

### Ownership and Cleanup

`Downloader` owns the task directory while the request is active.

- On cancellation or transport failure, `Downloader` closes the stream and removes its task directory.
- On success, `Downloader` transfers the downloaded file path to `LyricsFileDownloader` and leaves cleanup to that consumer.
- After an LRC is copied to the cache, `LyricsFileDownloader` removes the task directory.
- After a ZIP is processed, `LyricsFileDownloader` removes the task directory whether extraction succeeds or fails.
- `cleanAll()` continues to remove any task directories left by process termination or an older SDK version.

Cleanup failures are logged but do not replace the primary download or extraction result.

### Cache Resolution

Cache lookup derives the expected cached filename from the request URL path:

- `.zip` requests map to the same basename with an `.xml` extension.
- Other requests retain their original filename.

URL path APIs are used so query parameters do not become part of the cache filename. This matches the existing extraction convention, which expects a ZIP named `1.zip` to produce `1.xml`.

### Download Manager State

`DownloaderManager` removes its URL entry on both success and failure. This permits a failed full download to be retried. Cancellation already removes the entry before stopping the downloader.

### Compatibility Handling

If `LyricsFileDownloader` is deallocated after the low-level download succeeds but before it consumes the file, the completion closure must still remove the transferred task directory. Temporary ownership must not be lost through a weak-self early return.

## Error Handling

- Failure and cancellation never preserve partial data.
- HTTP status failures occur before a task file is opened and still release manager state.
- Extraction errors are reported as the existing `unzipFail` error after temporary cleanup.
- Cache-copy errors keep the existing public completion behavior but are logged and followed by temporary cleanup.

## Testing

Add focused, network-independent tests for:

- ZIP URL cache resolution from `.zip` to `.xml`, including query parameters.
- Non-ZIP cache resolution retaining its extension.
- Two download destinations with the same suggested filename being isolated by unique directories.
- Opening a destination for a fresh request truncating existing data rather than appending.
- Failure/cancellation cleanup removing the task directory.
- Manager failure releasing the URL so a retry is accepted.

Run the available project build or test entry point after the focused tests. If the repository cannot execute the CocoaPods test spec in the current environment, validate compilation with the available Xcode project and report that limitation explicitly.
