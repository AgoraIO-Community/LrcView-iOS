# TME 公共组件迁移计划

目标：把 Demo 内可复用的 TME 解析及资料准备能力迁入发布的 AgoraLyricsScore，Demo 只通过组件公开 API 引用。

结构：`AgoraLyricsScore/Class/TME` 保存 `TMEParser.swift`、`TMEParserModels.swift`、`TMEResponseTracker.swift`、`TMEScoringPreparation.swift`。前两者参考 Android 公开 parser/models 结构；后两者是现有 iOS 请求隔离与下载/解析流程。RTC/MCC/播放器业务、权限与播放门控继续由 Demo 负责。保留既有解析、异步主线程回调和取消逻辑。

- [x] 移动四份源码，公开 class/struct/protocol、外部读取的属性、初始化器和调用方法。Demo 的旧 TmeSongCatalog 也读取 envelope/status，因此这些 Decodable 响应模型一并公开；Catalog 添加组件 import 并做跨模块回归。
- [x] 移除 Demo 的四份文件引用及 Sources 条目，更新 CocoaPods 本地工程，让 podspec 现有 Class/**/*.swift 包含迁移文件。
- [x] 把解析器、回包过滤器、资料准备器回归测试改为 `import AgoraLyricsScore`，脚本先单独编译模块再编译调用方，验证 public 访问而非同模块可见性。
- [x] 更新 Demo/TME_SCORING.md，并增加组件内 TME 使用说明；保留用户已有 README 内容，仅更新迁移文件的四处链接。
- [x] 执行跨模块测试、Demo 接线检查、podspec/工程格式检查、Demo 构建及独立代码审查。无提交、发布、版本升级。

验证结果：

- 迁移前单独编译模块再编译 parser 测试，失败于 TMEParser/委托/结果模型无法跨模块访问，证明原 internal 接口不满足公共组件要求。
- `bash scripts/tests/tme_public_component.sh` 的 Parser、Tracker、Preparation、Catalog 四组测试通过。
- `bash scripts/tests/tme_sdk_flow.sh` 通过；两个 project.pbxproj 的 `plutil -lint` 通过。
- `pod install --no-repo-update` 成功，生成的 AgoraLyricsScore Pod target 已包含四份迁移源码。
- `xcodebuild -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/lrcview-ios-tme-migration-build ARCHS=x86_64 CODE_SIGNING_ALLOWED=NO build` 成功。初次沙箱内无法访问模拟器服务，按权限流程重试后成功。
- 独立审查对比原源码，只有 public 访问修饰及显式公共初始化器变更，未发现新的解析、异步或取消行为变化。
