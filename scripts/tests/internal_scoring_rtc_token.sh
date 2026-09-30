#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

rg -q 'static let rtcCertificate = LocalMccConfig\.rtcCertif' Demo/Demo/Config.swift
rg -q 'static let rtcCertif = ""' Demo/Demo/localConfig.example.swift
rg -Uq 'TokenBuilder\.rtcToken2\(Config\.rtcAppId,\s*appCertificate: Config\.rtcCertificate,\s*uid: Int32\(Config\.hostUid\),\s*channelName: Config\.channelId\)' Demo/Demo/Other/Utils/MccManager.swift
rg -q 'joinChannel\(byToken: token,' Demo/Demo/Other/Utils/MccManager.swift
if rg -q 'joinChannel\(byToken: nil,' Demo/Demo/Other/Utils/MccManager.swift; then
    echo 'internal scoring still joins RTC without a token' >&2
    exit 1
fi
rg -q 'guard let center = AgoraMusicContentCenter\.sharedContentCenter\(config: config\)' Demo/Demo/Other/Utils/MccManager.swift
rg -q 'guard mccManager\.initMCC\(\) else' Demo/Demo/VC/MainVC/MainTestVC.swift
