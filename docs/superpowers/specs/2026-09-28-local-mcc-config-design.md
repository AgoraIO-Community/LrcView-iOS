# Local MCC Credentials For Internal Demo

## Scope

The iOS Demo needs a local Agora Music Content Center App ID and its matching
certificate. This is for internal testing only. The values must not be committed
to Git. Other Demo credentials and the currently missing Pods are out of scope.

## Design

- Keep the tracked `Demo/Demo/Config.swift` free of real credentials. Its
  `mccAppId` and `mccCertificate` properties read from `LocalMccConfig.mccAppId`
  and `LocalMccConfig.mccCertif` respectively.
- Create `Demo/Demo/localConfig.swift` with those two string properties, initially
  empty for local entry. Register it as a Swift source in `Demo.xcodeproj`.
- Add the exact path to `.gitignore`. Commit a noncompiled
  `Demo/Demo/localConfig.example.swift` to show the expected structure. New
  checkouts must create their own local file before building.
- Do not remove `Config.swift` from Git: it contains only references and existing
  nonsensitive settings. No actual App ID, certificate, or token enters a
  tracked file.

## Verification And Limits

Check `git check-ignore -v Demo/Demo/localConfig.swift` and verify the file is
absent from `git ls-files`. Validate Xcode project syntax and inspect the source
references; a full build is conditional on the missing local Pods being supplied.
Ignoring a source file protects the repository, not the compiled app: the
certificate remains extractable from an internally distributed binary. A public
release must move certificate handling and token signing to a server.
