# TME Demo 计分接入设计

## 目标与边界

在 iOS Demo 的 TME 选歌流程中接入已有 `KaraokeView.parseTMEToneData` 与内部逐句计分。选歌后立即进入独立演唱页；正常情况下等媒体打开、`song-info` 返回、音高与 LRC 下载并解析完成后才播放。计分资料不可用时仍播放歌曲，但演唱页不显示歌词组件和计分区域。预加载、打开媒体或播放本身失败则不能播放，应显示相应错误。

该 Demo 同时作为可供其他开发者复制的接入示例。可复制部分以调用方已有 RTC engine、由该 RTC engine 初始化的 `AgoraMusicContentCenter` 和 music player 为前提，不创建或销毁这些 SDK 对象，不读取 Demo 的 `Config`，不包含选歌列表或凭证。`song-info` 必须通过 RTC 支撑的 MCC `sendExtRequest(jsonOption:)` 通道发送，并通过 MCC `onExtResponse` 接收；不用 RTC engine 的其他请求接口，也不用自行构造 HTTP `song-info` 请求。音高与 LRC 文件则按响应中的 URL 下载。

沿用已有 `TMEParser` / `TMEParserModels` 解析 `song-info`，沿用库内 `TMEToneParser`、`ScoringMachine` 和 `KaraokeView`，不更改既有计分算法、跳段不回调语义或边界采样规则。

## 组件职责及可复制入口

- 新增专注于资料获取的 `TMEScoringPreparation`。开始准备时输入当前 TME 原始 `songId` 和发送闭包 `(String) -> String?`；Demo 传入的闭包只调用已有 MCC 的 `sendExtRequest(jsonOption:)`。另提供接收 MCC `onExtResponse` 四个原始参数、准备阶段通知、成功/失败完成通知与 `cancel()`。组件构造请求、关联请求 ID、调用独立的 `TMEParser` 实例、下载文件、调用 `KaraokeView.parseTMEToneData(tonePath, lyricPath)` 并返回 `LyricModel`。不持有 RTC engine、MCC、播放器或 UIKit 页面。发送闭包及可注入的 URLSession 使无凭证测试能够模拟 SDK 响应和下载；生产调用链始终经过已有 MCC 通道。
- 现有 `TmeManager` 保留 RTC/MCC/player、列表请求、预加载和播放控制。它单独保存原始 `currentTMESongId` 与 MCC 内部 `selectedSongCode`，在预加载 `.OK` 后发起资料准备，在 `onExtResponse` 中将计分资料请求交给准备组件、其他请求交给原有列表解析器。它持有本次播放的状态，在媒体打开与资料准备结束后决定是否调用 `play()`；音高和进度通过委托送给演唱页。列表页与演唱页之间切换委托时不能把旧回调送给新歌曲。
- 新增独立的 `TmeSingingVC` 演示接入。它展示歌曲信息、准备状态、播放控制；资料就绪时以 `setLyricData(data:usingInternalScoring: true)` 装载模型，并显示 `KaraokeView` 音准/歌词、本句分与累计分。资料失败时隐藏整个歌词和计分区域，只保留失败提示、歌曲名称与播放控制。无需复制该页面的具体布局也能复用准备组件。
- 复制指引列出 `TMEScoringPreparation`、已有 `TMEParser` / `TMEParserModels` 及 Demo 中与 MCC 回调、RTC 音高、播放器进度、`KaraokeView` 相连的最小代码片段；明确 RTC/MCC/player 的创建和销毁由接入应用负责。`TMEResponseTracker` 的旧请求过滤行为可复用，但不能要求开发者复制 Demo 的曲库或配置文件。

## 选歌与资料时序

1. 列表页选择 `TmeSong` 时立即保存 `song.id` 为 `currentTMESongId`，另行调用 `getInternalSongCode` 取得播放专用整数 `songCode`，启动该歌曲预加载，并立即进入 `TmeSingingVC`。新歌曲开始前清除旧模型、得分、计时、文件及本次状态；歌曲 ID 不得换成内部 `songCode` 填入 `song-info`。
2. MCC `onPreLoadEvent` 只有匹配当前预加载请求 ID 与 `songCode` 且状态为 `.OK` 时才开始准备计分资料。发送的请求 JSON 为 `{"vendorId":2,"actionType":"song-info","actionParameter":{"songIdListStr":"<currentTMESongId>"}}`；通过结构化 JSON API 构造，保留真实歌曲 ID 原值。`openMedia(songCode:startPos: 0)` 可与计分资料准备并行，但 `.openCompleted` 不立即播放。
3. MCC `onExtResponse(requestId:jsonOption:httpCode:response:)` 只将属于当前 `song-info` 请求的响应转给准备组件；组件调用 `TMEParser.parse(...)`，在 `onSongInfo` 中从 `songList` 查找 `songId == currentTMESongId` 的条目，不依赖列表顺序。读取非空的 `pitchUrl`，从 `lrcList` 中选取 `type` **精确等于** `lrc` 且 URL 非空的条目；缺少任一资源即按资料失败处理。带签名的 URL 原样交给下载器，不拼接、不改写。
4. 两份资源分别下载到本次会话独有的本地目录，使用确定的本地文件名（例如 `song_pitch.json`、`song_lyric.lrc`），不能依赖远端 URL 的扩展名或把旧歌缓存误当成新歌。下载中分别报告“下载歌词中”“下载 pitch 中”，各自成功分别报告“下载歌词完成”“pitch 下载完成”；两个任务可并行，页面能同时表达各自的状态。文件完整落盘后调用 `KaraokeView.parseTMEToneData(pitchPath, lyricPath)`；返回 `nil` 等同资料失败。
5. 同时满足媒体 `.openCompleted` 与资料准备成功后，先安装模型，再调用播放器 `play()`。若计分资料请求、字段选择、下载或解析任一步失败，取消另一个仍在运行的下载，媒体一旦打开就不带歌词/计分播放，并向页面提供明确的失败原因；不能因资料失败无限等待。若预加载、`openMedia`、`play()` 失败则显示播放失败，不把它误当成可降级的资料错误。暂时停止/恢复沿用播放器的 `pause()` / `resume()`。

## 实时计分与页面状态

播放器开始后沿用 Demo 的 `ProgressProvider` 读取 player `getPosition()`、发出持续进度，并沿用现有播放/歌声对齐方式，将进度交给 `KaraokeView.setProgress(progress:)`。RTC engine 沿用 Demo 的 `enableAudioVolumeIndication(50, smooth: 3, reportVad: true)` 配置；当前本地 SDK 头文件说明小于 200 ms 的值会按 200 ms 处理，因此不能假定实际有 50 ms 的音高样本。取本地麦克风 `voicePitch`，在主线程交给 `KaraokeView.setPitch(speakerPitch:progressInMs: 0)`，不从远端音频或媒体伴奏取音高。`KaraokeDelegate.didFinishLineWith` 用 `score` 更新本句分，用 `cumulativeScore` 更新累计分，用 `lineCount * 100` 表示当前歌曲可计分句的满分；保留现有“只有自然播完句子才回调”的语义。计分资料失败时不发送音高/进度给隐藏的歌词组件。

状态明确区分预加载、查询资料、分别下载中与完成、解析、等待媒体、计分播放、无计分播放、暂停、播放结束和播放失败。下载状态显示在选歌后立即进入的演唱页，不要求用户等待在列表页。播放结束停止进度与音高输入、禁用继续按钮，保留最终得分直到退出。返回列表时停止当前媒体及进度，取消所有在途文件下载、清理本次生成的临时文件并重置 `KaraokeView`；列表页的 RTC/MCC 可以继续用于选下一首，只有退出 TME 功能时才销毁 RTC/MCC。

## 异步安全与清理

`song-info` 使用单独的请求关联与歌曲会话代数，不能与歌曲列表请求共用同一个当前请求 ID。SDK 未提供 `sendExtRequest` 取消入口时，取消会话后仅丢弃迟到的 SDK 响应和 `TMEParser` 主线程回调；两个 URLSession 下载任务要实际 `cancel()`。每个下载、状态与完成回调都检查歌曲会话身份和是否已取消，旧歌曲的回调不得启动播放器、覆盖新页面或写入新歌曲文件。下载落盘使用会话专属目录及原子写入/安全移动；成功解析后可以在不影响已载入模型的前提下清理文件，退出时清理尚存文件。不能记录带签名 URL、完整响应正文或凭证。

## 验证

- 无 RTC/MCC 凭证的测试覆盖所发送 JSON 的 `vendorId`、`actionType`、原始 `songIdListStr`，验证 SDK 响应确实通过 `TMEParser.onSongInfo` 而非新造 HTTP 接口解析；多歌曲响应只取匹配 ID，`lrcList` 只选 `type == "lrc"`。
- 模拟两份下载成功、其中一份失败、URL 缺失、`TMEParser` 错误与 `KaraokeView.parseTMEToneData` 返回 `nil`；验证准备阶段通知、可计分模型以及失败时无歌词播放的门槛。模拟媒体先打开和资料先完成两种顺序，确保 `play()` 恰好调用一次。
- 取消后模拟迟到 `song-info`、下载及解析回调，验证不会更新页面、写旧文件或启动播放；选择另一首歌时旧请求不能污染新会话。验证 RTC 音高、player 进度和逐句得分的页面接线，以及返回时停止播放、计时和下载。
- 运行库层 TME 解析/计分回归与 Demo 测试；具备真实凭证和设备时再做完整链路手动验证，包括资料失败的降级播放。仓库外的样例文件不是单元测试的硬编码依赖。
