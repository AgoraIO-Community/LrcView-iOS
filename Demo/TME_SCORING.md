# 在已有 RTC/MCC/播放器中接入 TME 计分

本示例假定业务已经持有入会后的 RTC 引擎、以该 RTC 引擎初始化的 MCC、音乐播放器和 `KaraokeView`。`TmeManager` / `TmeSingingVC` 是可运行的 Demo 接线示例，不需要复制它们的账号配置、歌曲列表或导航代码。

复制以下四个文件即可复用资料准备与播放门控：

- `Demo/Other/Utils/TMEParserModels.swift` 和 `TMEParser.swift`：解析 TME `song-info` 响应。
- `Demo/Other/Utils/TMEScoringPreparation.swift`：发送请求、选取原始 songId 的 `pitchUrl` 与 `lrcList` 中 `type == "lrc"` 的 URL、下载到临时文件并解析模型。
- `Demo/Other/Utils/TMEPlaybackGate.swift`：等待播放器 `openCompleted` 与模型准备成功/失败。

业务侧保留选歌时的原始字符串 `songId`（不要以 MCC 的内部数值 `songCode` 代替）。MCC 预加载 `.OK` 后，通过绑定当前 RTC 的 MCC 通道发送 `song-info`，并打开播放器：

```swift
let preparation = TMEScoringPreparation<LyricModel> { pitchFile, lyricFile in
    KaraokeView.parseTMEToneData(pitchFile, lyricFile)
}
let gate = TMEPlaybackGate()

// 选歌后按该首歌创建 gate；重复选歌时先 stop/cancel 旧的 gate/preparation。
gate.onStart = { mode in
    // mode == .playWithScoring 时显示歌词和分数，否则隐藏两者。
    // 这里调用现有播放器 play()，并处理其返回值。
}
preparation.onStatus = { status in
    // .downloadingLyrics / .lyricsDownloaded、.downloadingPitch / .pitchDownloaded
}
preparation.onCompletion = { result in
    switch result {
    case .success(let model):
        karaokeView.setLyricData(data: model, usingInternalScoring: true)
        gate.resourcesReady()
    case .failure:
        gate.resourcesFailed()  // 播放继续，但不显示歌词与计分组件。
    }
}

// MCC 的 onPreLoadEvent 收到当前请求的 .OK 时：
preparation.prepare(songId: currentTMESongId) { option in
    mcc.sendExtRequest(jsonOption: option)  // MCC 必须绑定已加入频道的 RTC。
}
player.openMedia(songCode: internalSongCode, startPos: 0)

// MCC 的 onExtResponse 中：只把当前 song-info 响应交给 preparation。
if !preparation.handleResponse(requestId: requestId, jsonOption: jsonOption,
                               httpCode: httpCode, response: response) {
    // 其他请求（例如歌曲列表）仍交给原有解析器。
}
// 播放器 openCompleted：gate.mediaOpened()
// 返回、切歌或停止：preparation.cancel(); gate.stop(); player.stop()
```

以上 `prepare`、`handleResponse` 和 `cancel` 从主线程调用；SDK 的 `onExtResponse` 若不在主线程，请先派发到主线程。切歌时同时隔离旧播放器回调（Demo 为每首歌重新创建播放器，并核对委托回调的播放器对象），否则旧歌曲的异步 `openCompleted` 可能打开新歌曲的门控。播放器异步 `.failed` 必须单独提示播放失败，不能按计分资料失败降级。准备器用独立的临时目录保存下载结果，调用 `cancel()` 会取消尚在运行的两个下载并清理该目录。请求失败、缺少资源、下载/解析失败都会让门控进入无计分播放。

在计分播放中，从 RTC 本地音量回调读取 `voicePitch`，主线程调用 `karaokeView.setPitch(speakerPitch: pitch, progressInMs: 0)`。用播放器 `getPosition()` 校准进度，并持续调用 `setProgress(progress:)`；Demo 使用 `ProgressProvider` 的 20ms 更新和已有 250ms 对齐。暂停时暂停进度，歌曲播放结束或退出时停止进度、重置 `KaraokeView`。句子分数由 `KaraokeDelegate.onKaraokeView(view:didFinishLineWith:score:cumulativeScore:lineIndex:lineCount:)` 接收；跳过的句子不触发计分回调。
