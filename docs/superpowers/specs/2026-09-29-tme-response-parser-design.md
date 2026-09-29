# TME Response Parser Design

## Scope

Add an iOS `TMEParser` for the Demo's Music Content Center `sendExtRequest` / `onExtResponse` flow. It dispatches by the original request's `jsonOption.actionType`, parses the response into typed results, and invokes a different success callback for each of the eight supported actions. Specify equivalent Android behavior, but do not add Android code or change unrelated Music Content Center clients.

The existing `TmeManager` forwards the SDK callback's `requestId`, `jsonOption`, `httpCode`, and response body to the parser. `TMEParser.parse(requestId:jsonOption:httpCode:responseBody:)` returns immediately, including for invalid input. The parser is owned by `TmeManager`; it does not send requests or own SDK objects.

## Scheduling And Lifecycle

Parse all inputs on one dedicated serial background queue in arrival order. Deliver all success and error callbacks with `DispatchQueue.main.async`, never inline, including when parsing is called from the main thread or fails before response decoding. A parser instance retains a weak delegate, so it does not prolong the UI owner's lifetime. The serial queue provides deterministic callback order for inputs submitted to that instance; it does not imply that network requests finish in submission order.

The parser reports every submitted response to its live delegate. `TmeManager` owns request validity: it compares returned `requestId` with the current outstanding request before updating its UI delegate, and clears its request ID when stopping or retrying. It also checks the ID for errors, so stale failures cannot overwrite a new screen state. No parsing or UI work blocks the SDK callback thread or the main thread.

## Dispatch And Callbacks

The request must be a JSON object with `vendorId: 2` and a supported string `actionType`; `actionParameter` is not needed for response decoding. A dedicated `TMEParserDelegate` exposes these typed callbacks, each carrying the original `requestId`:

| `actionType` | Success callback | Result |
| --- | --- | --- |
| `songs` | `onSongs` | `TMESongsResult` (`songList`, optional `nextQueryInfo`) |
| `search-song` | `onSearchSongs` | `TMESearchSongsResult` (`total`, `songList`) |
| `song-info` | `onSongInfo` | `TMESongInfoResult` (`songList`) |
| `song-url` | `onSongUrl` | `TMESongUrlResult` (`mediaList`) |
| `songlist-page` | `onSonglistPage` | `TMEPageResult` (`total`, `list`) |
| `songlist-detail` | `onSonglistDetail` | `TMEDetailResult` |
| `ranklist-page` | `onRanklistPage` | `TMEPageResult` (`total`, `list`) |
| `ranklist-detail` | `onRanklistDetail` | `TMEDetailResult` |

The four page/detail actions use shared data structures but remain separate callbacks. Every failed request calls exactly `onParseError(requestId, jsonOption, responseBody, error)` and no success callback. Preserve the exact original request and response strings, including malformed input. Do not log response bodies because song URLs can contain signed query parameters.

## Data Models

`songs`, `search-song`, and `song-info` decode the same complete song-detail model. Its required identity/display fields are `songId` and `songName`. Represent the remaining documented fields without silently discarding them: `version`, `duration`, `status`, `sequence`, `grantStatus`, `grantStartTime`, `publicTime`, `language`, `genre`, `grantedAreaCodes`, `pitchUrl`, `chorusStartMS`, `chorusEndMS`, `copyrightList` (`sceneId`, `terminalIdList`), `album` (`albumId`, `albumName`, `imagePathMapList` of `key`/`value`), `artistList` (`artistId`, `artistName`), and `lrcList` (`type`, `url`). Treat optional or absent metadata as optional so a valid song with fewer fields still decodes. Preserve strings such as dates and URLs verbatim; do not infer time zones or normalize signed URLs. Missing required fields or incorrect present field types are invalid responses.

`song-url` decodes each media entry's `fileType`, `url`, and `expire` as strings. A page entry contains `code`, `title`, and optional `description`, `url`, `status`; a detail contains `code`, `title`, optional `description`, `status`, `imgUrl`, and a list of song references containing `songId`. Use the response's distinct `url` (page) and `imgUrl` (detail) keys as-is. Page `total` and the lists are required; other metadata is optional where omission is shown in the examples.

The parser returns all songs and media entries. The Demo's existing six-song display limit and conversion to lightweight `TmeSong` belong in `TmeManager`, preserving current UI behavior without truncating reusable parser results. Share song decoding with the existing `TmeSongCatalog` implementation instead of maintaining two incompatible interpretations of song identity, while retaining the existing synchronous catalog test API.

## Errors

The typed `error` distinguishes invalid request JSON or missing/incorrect request fields, unsupported `actionType`, non-2xx HTTP response (including `httpCode`), nonzero API `code` (including `code` and optional `msg`), and malformed or incomplete successful response. Validate request envelope first, then HTTP status, then the common API envelope, then action-specific `data`. Error delivery obeys the same main-queue asynchronous guarantee as successful delivery.

## Android Parity

Android implements the same four-input contract, action names, result fields, error categories, request-ID correlation, and exactly-one-callback rule in native Kotlin. Use a dedicated single-thread executor for parsing and a main-looper handler to post callbacks. Java/Kotlin naming may follow platform conventions, but callback meaning and threading must match iOS. Neither platform shares binaries, introduces a cross-platform framework, or performs JSON decoding on the UI thread.

## Verification

Add local Swift tests with fixture bodies for all eight actions, nested song fields, empty lists, optional metadata, HTTP and API failures, invalid JSON, unsupported actions, and wrong field types. Verify callbacks are not inline, execute on the main thread, and arrive in input order. Add a manager-level test or focused harness for stale request IDs on both success and error paths. Run existing catalog and SDK-flow checks; the parser tests must not require real network access or SDK credentials.
