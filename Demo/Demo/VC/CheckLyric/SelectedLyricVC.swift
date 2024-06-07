//
//  SelectedLyricVC.swift
//  Demo
//
//  Created by ZYP on 2024/5/22.
//

import UIKit
import AgoraMccExService
import AgoraLyricsScore

class SelectedLyricVC: UIViewController {
    private let mccManager = MccManagerEx()
    let textField = UITextField()
    let confirmButton = UIButton()
    let logTag = "SelectedLyricVC"
    private var songId: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    private func setupUI() {
        title = "init..."
        view.backgroundColor = .white
        textField.text = "\(89488966)"
        textField.placeholder = "请输入歌曲id"
        textField.borderStyle = .roundedRect
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            textField.leftAnchor.constraint(equalTo: view.leftAnchor),
            textField.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        confirmButton.isEnabled = false
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.setTitleColor(.gray, for: .disabled)
        confirmButton.backgroundColor = .blue
        confirmButton.addTarget(self, action: #selector(confirmButtonClicked), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            confirmButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func commonInit() {
        Log.info(text: "commonInit", tag: logTag)
        mccManager.delegate = self
        if let token = Config.token, let userId = Config.userId {
            mccManager.initRtcEngine()
            mccManager.joinChannel()
            mccManager.initMccEx(pid: Config.pid,
                                 pKey: Config.pKey,
                                 token: token,
                                 userId: userId)
        }
        else {
            AccessProvider.fetchAccessData { [weak self](userId, token, errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg  {
                    Log.errorText(text: errorMsg, tag: logTag)
                    showAlertVC()
                    return
                }
                mccManager.initRtcEngine()
                mccManager.joinChannel()
                self.mccManager.initMccEx(pid: Config.pid,
                                          pKey: Config.pKey,
                                          token: token,
                                          userId: userId)
            }
        }
    }
    
    private func showAlertVC() {
        let alertVC = UIAlertController(title: "获取权限失败",
                                        message: "请检查网络连接",
                                        preferredStyle: .alert)
        let action = UIAlertAction(title: "确定",
                                   style: .default,
                                   handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alertVC.addAction(action)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc func confirmButtonClicked() {
        guard let text = textField.text,
              let songId = Int(text) else {
            return
        }
        title = "loading"
        self.songId = mccManager.getInternalSongCode(songId: songId)
        mccManager.preload(songId: self.songId)
    }
}
// MARK: - RTCManagerDelegate
extension SelectedLyricVC: MccManagerDelegateEx {
    func onMccExInitialize(_ manager: MccManagerEx) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.confirmButton.isEnabled = true
            title = "init ok"
        }
    }
    
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        lyricData: Data,
                        pitchData: Data,
                        percent: Int,
                        errMsg: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let text = textField.text,
                  let songId = Int(text) else {
                return
            }
            title = "load ok"
            let vc = CheckLyricVC(krcFileData: lyricData, pitchFileData: pitchData, songId: songId)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func onMccExScoreStart(_ manager: MccManagerEx) {}
    func onOpenMusic(_ manager: MccManagerEx) {}
    func onPitch(_ songCode: Int, data: AgoraRawScoreData) {}
    func onLineScore(_ songCode: Int, value: AgoraLineScoreData) {}
}

