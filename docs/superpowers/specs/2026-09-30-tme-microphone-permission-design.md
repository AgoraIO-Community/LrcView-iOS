# TME Demo 麦克风权限设计

## 目标

进入 TME 选歌页时主动请求麦克风权限，只有授权后才初始化 RTC 并请求歌曲。拒绝授权时不以 0 分演唱页误导用户，而是在选歌页提示去 iOS 设置中允许麦克风。只修改 Demo 的 TME 启动和权限用途文案；不改变评分算法、RTC 音高提取及其他 Demo 页面。

## 启动流程

`TmeTestVC` 仍在页面加载时调用 `TmeManager.start()`，重试按钮也沿用该入口。`start()` 先检查现有 RTC/MCC 配置；若已初始化 MCC，则沿用当前刷新歌曲逻辑。否则在创建 RTC engine 之前读取 `AVAudioSession.sharedInstance().recordPermission`：

- `.granted`：继续现有 RTC、MCC 和歌曲列表初始化。
- `.undetermined`：调用 `requestRecordPermission`，等待系统弹窗的异步结果。允许后回到主线程继续初始化；拒绝后通过已有委托在列表页显示“请在系统设置中允许麦克风权限后重试”，不创建 RTC/MCC。
- `.denied`：不重复弹窗、不创建 RTC/MCC，直接显示相同提示。用户去系统设置授权、回到 Demo 后点击重试时，重新检查权限并继续。

等待授权期间，`start()` 的重复调用不应发起多个请求或创建多个 RTC engine。若用户退出 TME 页面，`stop()` 必须令待返回的权限回调失效，不能在离开后重新初始化 RTC 或覆盖其他页面状态。权限回调只触发该会话的后续启动，不持有页面或发送凭证。已授权的原有播放行为保持不变。

项目中 Debug/Release 两处 `NSMicrophoneUsageDescription` 均改成准确说明录音用于演唱音高与计分，不再提“相机功能”。不调用 `simctl privacy grant` 预先代替用户同意。

## 验证

先加失败的权限流程检查，再改生产代码：覆盖已授权直接启动、尚未决定只请求一次并按结果分流、已拒绝不启动、页面退出后丢弃迟到授权回调。运行现有 TME 接线检查与 Demo 模拟器构建。使用 iPhone 14 模拟器的当前 Demo 包标识，验证首次进入显示系统麦克风弹窗、拒绝后出现提示且不能进入演唱页；用户授权后重试能加载列表并运行演唱页。观察 RTC 日志不再持续报告 `record permission undetermined`；非零分还需要实际麦克风输入，授权本身不保证得分。
