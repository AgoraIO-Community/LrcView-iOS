import UIKit

final class ConfigurationViewController: UIViewController {
    var onSave: ((AgoraCredentials) -> Void)?
    var onClear: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let appIdField = UITextField()
    private let certificateField = UITextField()
    private let validationLabel = UILabel()
    private let clearButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureForm()
    }

    func populate(_ credentials: AgoraCredentials?) {
        loadViewIfNeeded()
        appIdField.text = credentials?.appId
        certificateField.text = credentials?.appCertificate
        clearButton.isHidden = credentials == nil
    }

    private func configureView() {
        title = "Agora 配置"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -28)
        ])
    }

    private func configureForm() {
        stackView.axis = .vertical
        stackView.spacing = 16

        let heading = UILabel()
        heading.text = "连接 Agora 服务"
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true

        let introduction = UILabel()
        introduction.text = "输入项目的 App ID 和 App Certificate。"
        introduction.font = .preferredFont(forTextStyle: .body)
        introduction.textColor = .secondaryLabel
        introduction.numberOfLines = 0

        configureTextField(appIdField, placeholder: "32 位 App ID")
        appIdField.accessibilityLabel = "App ID"
        appIdField.autocapitalizationType = .none
        appIdField.returnKeyType = .next
        appIdField.delegate = self

        configureTextField(certificateField, placeholder: "32 位 App Certificate")
        certificateField.accessibilityLabel = "App Certificate"
        certificateField.isSecureTextEntry = true
        certificateField.autocapitalizationType = .none
        certificateField.returnKeyType = .done
        certificateField.delegate = self

        let visibilityButton = UIButton(type: .system)
        visibilityButton.setImage(UIImage(systemName: "eye"), for: .normal)
        visibilityButton.accessibilityLabel = "显示或隐藏证书"
        visibilityButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        visibilityButton.addTarget(self, action: #selector(toggleCertificateVisibility(_:)), for: .touchUpInside)
        certificateField.rightView = visibilityButton
        certificateField.rightViewMode = .always

        let warning = UILabel()
        warning.text = "仅用于内部演示。App Certificate 会保存在本机钥匙串中，请勿用于公开发布。"
        warning.font = .preferredFont(forTextStyle: .footnote)
        warning.textColor = .systemOrange
        warning.numberOfLines = 0

        validationLabel.font = .preferredFont(forTextStyle: .footnote)
        validationLabel.textColor = .systemRed
        validationLabel.numberOfLines = 0
        validationLabel.isHidden = true
        validationLabel.accessibilityIdentifier = "credentialValidationError"

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("保存并继续", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.backgroundColor = .systemBlue
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 8
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        clearButton.setTitle("清除配置", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        clearButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(confirmClear), for: .touchUpInside)

        [heading, introduction, makeFieldGroup(title: "App ID", field: appIdField),
         makeFieldGroup(title: "App Certificate", field: certificateField), warning,
         validationLabel, saveButton, clearButton].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(24, after: introduction)
        stackView.setCustomSpacing(24, after: warning)
    }

    private func configureTextField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.clearButtonMode = .whileEditing
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.addTarget(self, action: #selector(clearValidation), for: .editingChanged)
    }

    private func makeFieldGroup(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel

        let group = UIStackView(arrangedSubviews: [label, field])
        group.axis = .vertical
        group.spacing = 6
        return group
    }

    @objc private func toggleCertificateVisibility(_ sender: UIButton) {
        certificateField.isSecureTextEntry.toggle()
        let symbol = certificateField.isSecureTextEntry ? "eye" : "eye.slash"
        sender.setImage(UIImage(systemName: symbol), for: .normal)
    }

    @objc private func save() {
        view.endEditing(true)
        do {
            let credentials = try AgoraCredentials(
                appId: appIdField.text ?? "",
                appCertificate: certificateField.text ?? ""
            )
            clearValidation()
            onSave?(credentials)
        } catch CredentialValidationError.invalidAppId {
            showValidation("App ID 必须是 32 位十六进制字符")
        } catch CredentialValidationError.invalidCertificate {
            showValidation("App Certificate 必须是 32 位十六进制字符")
        } catch {
            showValidation("配置无效，请检查后重试")
        }
    }

    @objc private func clearValidation() {
        validationLabel.text = nil
        validationLabel.isHidden = true
    }

    private func showValidation(_ message: String) {
        validationLabel.text = message
        validationLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    @objc private func confirmClear() {
        let alert = UIAlertController(
            title: "清除 Agora 配置？",
            message: "App ID 和 App Certificate 将从本机钥匙串中删除。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { [weak self] _ in
            self?.onClear?()
        })
        present(alert, animated: true)
    }
}

extension ConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === appIdField {
            certificateField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            save()
        }
        return true
    }
}
