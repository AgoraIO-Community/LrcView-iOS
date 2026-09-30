#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

rg -q 'pod .AgoraRtcEngine_iOS., :path => .Vendor/AgoraRtcEngine_iOS.' Demo/Podfile
if rg -q 'pod .AgoraMccExService.|pod .AgoraRtcEngine_Special_iOS.' Demo/Podfile; then
    echo 'legacy RTC or ExService dependency is still enabled' >&2
    exit 1
fi
rg -q 'TME测试' Demo/Demo/ViewController.swift
rg -q 'sendExtRequest\(jsonOption:' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'func onExtResponse\(' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'getInternalSongCode\(songCode: 0, jsonOption:' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'preload\(songCode:' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'openMedia\(songCode:' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'TokenBuilder\.rtcToken2' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'TokenBuilder\.buildRtmToken2' Demo/Demo/Other/Utils/TmeManager.swift
rg -q '\.playBackAllLoopsCompleted' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'status\(isPlaying \? "正在播放" : "已暂停"\)' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'state == \.failed' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'self\.stopSong\(\)' Demo/Demo/Other/Utils/TmeManager.swift
rg -Fq 'navigationController?.pushViewController' Demo/Demo/VC/MainVC/TmeTestVC.swift
rg -q 'manager.stopSong\(' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'setLyricData\(data: model, usingInternalScoring: true\)' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'setProgress\(progress:' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'setPitch\(speakerPitch:' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'didFinishLineWith model:' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'scoringPreparation.prepare\(songId:' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'didFailPreparation: error' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'case \.downloadFailed:' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'fallbackLabel.text = "计分资料下载失败' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -Fq 'speakers.first(where: { $0.uid == 0 })?.voicePitch' Demo/Demo/Other/Utils/TmeManager.swift
rg -Fq 'if state == .failed' Demo/Demo/Other/Utils/TmeManager.swift
rg -Fq '(playerKit as AnyObject) === (current as AnyObject)' Demo/Demo/Other/Utils/TmeManager.swift
rg -Fq 'center.createMusicPlayer(delegate: self)' Demo/Demo/Other/Utils/TmeManager.swift
rg -Fq 'karaokeView.lyricsView.activeLineUpcomingTextColor = .label' Demo/Demo/VC/MainVC/TmeSingingVC.swift
rg -q 'TMEMicrophonePermissionGate.swift in Sources' Demo/Demo.xcodeproj/project.pbxproj
rg -q 'recordPermission' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'requestRecordPermission' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'microphonePermission.cancel()' Demo/Demo/Other/Utils/TmeManager.swift
rg -q '请在系统设置中允许麦克风权限后重试' Demo/Demo/Other/Utils/TmeManager.swift
test "$(rg -c 'INFOPLIST_KEY_NSMicrophoneUsageDescription = "允许录音以检测演唱音高并计算得分";' Demo/Demo.xcodeproj/project.pbxproj)" -eq 2
