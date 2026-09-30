# TME Tone Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 TME 音高 JSON 文件和标准 LRC 文件合并为可显示、可逐句打分的 `LyricModel`，保留现有解析行为。

**Architecture:** `KaraokeView` 提供两条本地文件路径的同步入口，`TMEToneParser` 独立解析 JSON 和 LRC、生成所有显示行及可计分行列表。`ScoringMachine` 对普通模型仍使用所有 `lines`，仅对 TME 模型使用单独的可计分行列表，并在 TME 路径采用半开区间匹配。

**Tech Stack:** Swift、Foundation `JSONSerialization`/正则表达式、现有 UIKit `KaraokeView`、XCTest。

**Spec:** `docs/superpowers/specs/2026-09-29-tme-tone-data-design.md`

---

### Task 1: 新接口与数据解析

**Files:**
- Create: `AgoraLyricsScore/Class/Other/TMEToneParser.swift`
- Modify: `AgoraLyricsScore/Class/KaraokeView.swift:73-90`
- Modify: `AgoraLyricsScore/Class/Model.swift:41-86`
- Test: `AgoraLyricsScore/Tests/TestParser/TestTMEToneParser.swift`

- [ ] **Step 1: 写失败的解析测试。** 在 XCTest 中用专属临时目录生成两个文件，用 `defer` 清理；先验证公开入口缺失导致编译失败，再依次验证十进制时间、音高转换、元数据保留及无音高行保留：

```swift
func testTMEConvertsNotesAndKeepsDisplayLines() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let lyricPath = folder.appendingPathComponent("song_lyric.txt")
    let pitchPath = folder.appendingPathComponent("song_pitch.txt")
    let lyrics = "[ti:要强]\n[ar:房祖名]\n[00:00.00]要强 - 房祖名\n[00:01.20]词：某人\n[00:02.30]唱一句\n[00:03.40]下一句\n[00:04.00]"
    let pitches = """
    [{"st":"1200","d":"100","p":"54"},
     {"st":"2300","d":"300","p":"32"},
     {"st":3400,"d":200,"p":44},
     {"st":3500,"d":100,"p":20}]
    """
    try Data(lyrics.utf8).write(to: lyricPath)
    try Data(pitches.utf8).write(to: pitchPath)
    let model = try XCTUnwrap(KaraokeView.parseTMEToneData(pitchPath.path, lyricPath.path))
    XCTAssertEqual(model.lines.count, 5)
    XCTAssertEqual(model.lines[2].beginTime, 2300)
    XCTAssertEqual(model.lines[2].tones[0].pitch, 55 * (1 - 1e-6), accuracy: 1e-6)
    XCTAssertEqual(model.scoringLines?.count, 2)
    XCTAssertEqual(model.scoringLines?.first?.content, "唱一句")
}
```

- [ ] **Step 2: 运行新测试，确认因 API 缺失而失败。** 新测试文件要先通过 `pod install --project-directory=Demo --no-repo-update` 注册到测试 target；该命令可能重建 `Demo/Pods`，运行前确认不覆盖用户的手改文件。随后执行 `xcodebuild test -workspace Demo/Demo.xcworkspace -scheme AgoraLyricsScore-Unit-Tests -destination 'platform=iOS Simulator,id=886F78E2-A8B3-4C33-884B-874878DDBCF4' -derivedDataPath /tmp/kl-tme-tone-derived -only-testing:AgoraLyricsScore-Unit-Tests/TestTMEToneParser`，预期因缺少 `parseTMEToneData` 编译失败。若本机模拟器 ID 发生变化，先运行 `xcrun simctl list devices available`，再替换目的设备 ID。

- [ ] **Step 3: 添加模型标记和公开入口。** 在 `LyricModel` 添加仅供模块内部使用的可选 `scoringLines: [LyricLineModel]? = nil`；在 `KaraokeView` 加入：

```swift
@objc public static func parseTMEToneData(_ toneFilePath: String,
                                           _ lyricFilePath: String) -> LyricModel? {
    guard let tone = try? Data(contentsOf: URL(fileURLWithPath: toneFilePath)),
          let lyric = try? Data(contentsOf: URL(fileURLWithPath: lyricFilePath)) else { return nil }
    return TMEToneParser().parse(tone: tone, lyric: lyric)
}
```

- [ ] **Step 4: 实现 `TMEToneParser.parse(tone:lyric:)`。** 使用 `JSONSerialization.jsonObject` 解析 `[Any]`，逐项安全读取字串/数字 `st/d/p`；检查 `st >= 0`、`d > 0`、`st + d` 不溢出、`p >= 32` 且转换后音高有限；无效项跳过。LRC 用捕获组解析元数据及 `[mm:ss.fraction]` 行，按小数位数统一成毫秒，排序且保留文本；对每个 JSON 片段按 `st` 二分或顺序查找 `[lineStart, nextLineStart)`，并裁剪 `duration`，只把可唱行加入 `scoringLines`。标题通过歌名/歌手元数据识别，署名识别 `词：`、`曲：`、`作词：`、`作曲：`、`编曲：` 等前缀；文字仅设在 `line.content`。模型 `lyricsType = .lrc`、`hasPitch = true`、`preludeEndPosition = scoringLines[0].beginTime`，无可计分片段则返回 `nil`。核心转换函数：

```swift
private func pitch(for tone: Double) -> Double? {
    guard tone.isFinite, tone >= 32 else { return nil }
    let result = 55 * (pow(2, (tone - 32) / 12) - 1e-6)
    return result.isFinite && result > 0 ? result : nil
}
```

实现时每个子用例遵循红-绿-重构，不一次加入所有逻辑。

- [ ] **Step 5: 扩展测试并运行绿色验证。** 分别测试纯坏记录返回 `nil`、混合坏记录继续、JSON 顶层非数组返回 `nil`、无有效时间行返回 `nil`、`st` 在行边界归下一行、跨行时长截断、字幕空行/署名即使有音高也不计分、末行时长、文件读取失败；旧 `TestParser` 的 XML/LRC 用例仍通过。命令使用 Step 2 的同一 scheme，预期新旧解析用例均通过。

### Task 2: 内部打分器兼容可计分行

**Files:**
- Modify: `AgoraLyricsScore/Class/Scoring/ScoringMachine/ScoringMachine.swift:33-40,101-112,175-189,223-258,279-328`
- Modify: `AgoraLyricsScore/Class/Scoring/ScoringMachine/ScoringMachine+DataHandle.swift:14-47,147-154`
- Test: `AgoraLyricsScore/Tests/TestScoringMachine/TestTMEToneScoring.swift`

- [ ] **Step 1: 写失败的异步回调测试。** 构建包含标题、署名、两条可计分行及空行的 TME 模型；实现 `ScoringMachineDelegate` 收集 `didFinishLineWith`，先后推入进度和与目标频率相同的实时音高，用 XCTest expectation 等待主线程回调；断言回调仅有两次，`lineIndex = [0,1]`、`lineCount = 2`、`model.content` 是两条歌词、累计得分等于两句得分之和。另断言 TME 在片段右边界没有命中、旧 XML 在右边界仍命中。

- [ ] **Step 2: 运行测试验证因评分仍使用所有 `lines` 而失败。** 新测试文件注册到 test target 后，使用 Task 1 的 `xcodebuild test` 命令，将 `-only-testing:` 值改为 `AgoraLyricsScore-Unit-Tests/TestTMEToneScoring`；预期收到错误行数/索引或缺失回调。

- [ ] **Step 3: 最小调整评分行来源。** 将 `ScoringMachine` 中全部创建字分、计算句末分数、拖拽重置、回调 `lineCount` 的 `lyricData.lines` 读取替换为实例保存的 `scoringLines = lyricData.scoringLines ?? lyricData.lines`；`ScoringMachine.createData` 也从相同集合展开，但不能修改原始显示模型的 `lines`。`getHitedInfo` 新增默认参数 `includeEnd: Bool = true`，仅 TME 调用传 `false`，保持所有现存调用的闭区间行为；右边界按 `progress < info.endTime` 匹配。`reset()` 同时清除缓存的计分行。关键边界如下：

```swift
let scoringLines = lyricData.scoringLines ?? lyricData.lines
// 仅在新路径关闭旧实现包含右边界的匹配行为。
let hit = getHitedInfo(progress: progress,
                       currentVisiableInfos: currentVisiableInfos,
                       includeEnd: lyricData.scoringLines == nil)
```

- [ ] **Step 4: 跑评分与解析回归测试。** 命令沿用确定的 scheme，分别运行 `TestTMEToneScoring`、`TestScoringVM` 和 `TestParser`；预期仅有效歌词行计分，原 XML 最右边界与旧解析结果不变。

### Task 3: 样例验证与交付检查

**Files:**
- Test: `AgoraLyricsScore/Tests/TestParser/TestTMEToneParser.swift`

- [ ] **Step 1: 增加样例级断言。** 使用内嵌简化数据覆盖 `[00:43.30]` 为 `43300 ms`、`p = 54` 生成约 `196 Hz`；如 CI 环境提供仓库外 `docs/song_pitch.txt` 和 `docs/song_lyric.txt`，额外做一次人工读入验证，但单元测试不依赖该绝对路径。

- [ ] **Step 2: 完整运行测试与差异检查。** 运行 `xcodebuild test -workspace Demo/Demo.xcworkspace -scheme AgoraLyricsScore-Unit-Tests -destination 'platform=iOS Simulator,id=886F78E2-A8B3-4C33-884B-874878DDBCF4' -derivedDataPath /tmp/kl-tme-tone-derived` 覆盖目标 Pod 全部测试；`git diff --check` 检查空白问题；`git status --short` 核对只修改计划中的模块和测试，保留工作区原有 Demo 改动。编译/模拟器不可用时报告具体阻碍与已经运行的替代验证，不能声称测试通过。

- [ ] **Step 3: 提交本功能的文件。** 仅暂存本计划列出的源码和测试文件，先用 `git diff --cached --name-only` 确认目标，再以 `git commit -m 'feat: parse TME tone and LRC data for scoring'` 提交；不包含其他工作区变动。
