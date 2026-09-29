# TME 响应解析器设计

## 范围

为 Demo 的 Music Content Center `sendExtRequest` / `onExtResponse` 流程增加 iOS `TMEParser`。解析器根据原请求中的 `jsonOption.actionType` 分派解析逻辑，将响应转换为类型明确的结果，并为八种支持的操作分别触发不同的成功回调。设计同时规定 Android 的对等行为，但本次不编写 Android 代码，也不改动无关的 Music Content Center 调用方。

现有 `TmeManager` 将 SDK 回调中的 `requestId`、`jsonOption`、`httpCode` 和响应正文转交解析器。`TMEParser.parse(requestId:jsonOption:httpCode:responseBody:)` 立即返回，即使输入无效也是如此。解析器由 `TmeManager` 持有，不负责发送请求，也不持有 SDK 对象。

## 线程调度与生命周期

所有输入按进入解析器的顺序，在一个专用后台串行队列中解析。所有成功和失败回调都通过 `DispatchQueue.main.async` 投递，绝不在 `parse` 调用栈内直接触发；从主线程调用或在解码前发现错误时也一样。解析器弱引用其委托，避免延长 UI 持有者的生命周期。串行队列保证同一解析器收到的输入按入队顺序回调，但不保证网络请求按发送顺序完成。

解析器会向仍存活的委托报告每个已提交的响应。`TmeManager` 负责判断请求是否仍有效：更新 UI 委托前比较返回的 `requestId` 与当前待完成请求，停止或重试时清除旧请求 ID。错误回调也执行同样的检查，避免旧错误覆盖新页面状态。解析和 UI 处理均不阻塞 SDK 回调线程或主线程。

## 分派与回调

请求必须是包含 `vendorId: 2` 和受支持的字符串 `actionType` 的 JSON 对象；解析响应不需要读取 `actionParameter`。专用的 `TMEParserDelegate` 提供以下类型明确的回调，每个成功回调都携带原始 `requestId`：

| `actionType` | 成功回调 | 结果 |
| --- | --- | --- |
| `songs` | `onSongs` | `TMESongsResult`（`songList`、可选的 `nextQueryInfo`） |
| `search-song` | `onSearchSongs` | `TMESearchSongsResult`（`total`、`songList`） |
| `song-info` | `onSongInfo` | `TMESongInfoResult`（`songList`） |
| `song-url` | `onSongUrl` | `TMESongUrlResult`（`mediaList`） |
| `songlist-page` | `onSonglistPage` | `TMEPageResult`（`total`、`list`） |
| `songlist-detail` | `onSonglistDetail` | `TMEDetailResult` |
| `ranklist-page` | `onRanklistPage` | `TMEPageResult`（`total`、`list`） |
| `ranklist-detail` | `onRanklistDetail` | `TMEDetailResult` |

歌单和榜单的四种分页/详情操作复用数据结构，但分别触发各自的回调。每个失败请求只触发 `onParseError(requestId, jsonOption, responseBody, error)`，不触发成功回调。即使输入格式有误，也要在错误回调中原样保留请求和响应字符串。歌曲 URL 可能包含签名参数，不得记录响应正文日志。

## 数据模型

`songs`、`search-song` 和 `song-info` 使用同一种完整的歌曲详情模型。标识和展示所需的 `songId`、`songName` 为必填字段。其余已知字段也必须保留，不得静默丢弃：`version`、`duration`、`status`、`sequence`、`grantStatus`、`grantStartTime`、`publicTime`、`language`、`genre`、`grantedAreaCodes`、`pitchUrl`、`chorusStartMS`、`chorusEndMS`、`copyrightList`（`sceneId`、`terminalIdList`）、`album`（`albumId`、`albumName`，以及由 `key` / `value` 组成的 `imagePathMapList`）、`artistList`（`artistId`、`artistName`）和 `lrcList`（`type`、`url`）。允许可选元数据缺失，使字段较少的有效歌曲仍可解析。日期和 URL 等字符串保持原值，不推断时区，也不改写带签名的 URL。必填字段缺失或已提供字段类型错误时，判定响应无效。

`song-url` 将每个媒体条目的 `fileType`、`url` 和 `expire` 按字符串解析。分页条目包含必填的 `code`、`title`，以及可选的 `description`、`url`、`status`；详情包含必填的 `code`、`title`，可选的 `description`、`status`、`imgUrl`，以及包含 `songId` 的歌曲引用列表。分页中的 `url` 和详情中的 `imgUrl` 是不同的原始键名，应分别保留。分页的 `total` 和各列表为必填；样例中可能省略的其他元数据为可选。

解析器返回全部歌曲和媒体条目。Demo 现有的“最多展示六首”规则及轻量 `TmeSong` 的转换留在 `TmeManager`，既保持现有 UI 行为，也不截断通用解析结果。歌曲解码逻辑应与现有 `TmeSongCatalog` 共用，避免出现两套不一致的歌曲标识解析规则；同时保留现有供同步测试使用的曲库解析接口。

## 错误处理

具有明确类型的 `error` 区分以下情况：请求 JSON 无效或请求字段缺失、类型错误；`actionType` 不受支持；HTTP 状态不在 2xx 范围内（保留 `httpCode`）；业务 `code` 非零（保留 `code` 和可选的 `msg`）；成功响应格式错误或内容不完整。检查顺序为请求结构、HTTP 状态、通用业务响应结构，最后是对应操作的 `data`。错误回调与成功回调遵守相同的主线程异步投递规则。

## Android 对等约定

Android 将来用原生 Kotlin 实现同样的四参数输入约定、操作名称、结果字段、错误类别、请求 ID 关联，以及“每次解析恰好触发一次回调”的规则。解析使用专用的单线程执行器，回调通过主线程 `Looper` 对应的 `Handler` 投递。Java/Kotlin 命名可遵循平台习惯，但回调含义和线程行为必须与 iOS 一致。两端不共用二进制、不引入跨平台框架，也不在 UI 线程进行 JSON 解码。

## 验证

为八种操作、歌曲嵌套字段、空列表、可选元数据、HTTP 与业务错误、无效 JSON、未知操作和字段类型错误编写本地 Swift 测试。验证回调不会同步触发、一定在主线程执行，且按输入顺序到达。通过管理器级测试或专门的测试程序覆盖成功和失败两条路径的旧请求 ID 过滤。运行现有曲库及 SDK 流程检查；解析器测试不得依赖真实网络或 SDK 凭据。
