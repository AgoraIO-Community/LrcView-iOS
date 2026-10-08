# TME 公共接口

`TMEParser`、`TMEParserDelegate`、`TMEParseError`、全部 Decodable 响应模型、`TMEResponseTracker`、`TMEScoringPreparation` 已从 Demo 迁入 `AgoraLyricsScore/Class/TME`。CocoaPods 的 `Class/**/*.swift` 自动包含这些源码，Demo 通过本地 Pod 引用；对外发布包含此次变更的组件版本后，业务可直接导入使用。

## 解析 SDK 回包

```swift
import AgoraLyricsScore

final class SongsReceiver: TMEParserDelegate {
    private let parser = TMEParser()

    init() {
        parser.delegate = self
    }

    func handleResponse(requestId: String, jsonOption: String,
                        httpCode: Int, responseBody: String) {
        parser.parse(requestId: requestId, jsonOption: jsonOption,
                     httpCode: httpCode, responseBody: responseBody)
    }

    func onSongs(_ requestId: String, result: TMESongsResult) {
        // 主线程，result.songList 保留完整歌曲列表。
    }

    func onParseError(_ requestId: String, jsonOption: String,
                      responseBody: String, error: TMEParseError) {
        // 主线程，按错误类型处理请求、HTTP、业务或解码错误。
    }
}
```

业务应持有 `SongsReceiver`；解析器只弱引用委托。`parse` 可接收 SDK 后台线程的回包，在独立串行队列解析后异步投递到主线程。支持 `songs`、`search-song`、`song-info`、`song-url`、`songlist-page`、`songlist-detail`、`ranklist-page`、`ranklist-detail`，只实现需要的委托方法即可。响应模型字段只读，通过解析器回调或 `JSONDecoder` 获取。

## 过滤重试、退出和重复回包

`TMEResponseTracker()` 用于业务当前请求隔离；在主线程使用 `set(requestId)` 标记请求，在退出/切歌时 `clear()`。成功和错误回调内使用 `deliverIfCurrent` 过滤旧/重复结果：

```swift
tracker.deliverIfCurrent(requestId) { isStillCurrent in
    updateSongs(result.songList)
    // UI 更新若重入并发起新请求，继续更新旧状态前再判断。
    guard isStillCurrent() else { return }
    updateStatus()
}
```

每个独立请求流程使用独立 tracker。tracker 不持有或创建 RTC/MCC，也不取消 SDK 请求；发送和转交回包仍由业务负责。

## 准备歌词和音高文件

```swift
let preparation = TMEScoringPreparation<LyricModel> { pitchPath, lyricPath in
    KaraokeView.parseTMEToneData(pitchPath, lyricPath)
}
preparation.onCompletion = { result in
    if case .success(let model) = result {
        karaokeView.setLyricData(data: model, usingInternalScoring: true)
    }
}
preparation.prepare(songId: originalTMESongId) { option in
    mcc.sendExtRequest(jsonOption: option)
}
// SDK 响应转到主线程后：
preparation.handleResponse(requestId: requestId, jsonOption: jsonOption,
                           httpCode: httpCode, response: responseBody)
// 切歌/退出：preparation.cancel()
```

调用方持有 preparation；`prepare`、`handleResponse`、`cancel` 从主线程调用，状态与完成回调也在主线程。它通过业务的发送闭包请求 `song-info`，选择匹配原始 songId 的 pitch/LRC 资料，用注入的 URLSession 下载并调用解析闭包。`cancel` 会过滤旧回包、取消下载并清理专属临时目录。该组件不创建 RTC/MCC，不控制播放器。完整 Demo 接线见 [TME_SCORING](../Demo/TME_SCORING.md)。

## 验证迁移

```bash
bash scripts/tests/tme_public_component.sh
bash scripts/tests/tme_sdk_flow.sh
```

第一条单独编译组件内实际四份 Foundation 源码为模块，再将解析器、tracker、资料准备器和 Demo 歌曲映射测试作为外部调用方编译并执行，不使用 `@testable import`；因此可验证公开可见性。它不替代完整 iOS framework 与 Demo 的 Xcode 编译。第二条检查 Demo 的 SDK 接线。
