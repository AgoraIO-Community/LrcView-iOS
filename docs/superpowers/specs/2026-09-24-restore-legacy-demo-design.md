# Restore Legacy Demo Design

## Goal

Restore the iOS Demo to its legacy implementation while retaining the upstream
`2.1.7-beta-3` update and the repository's existing history.

## Approach

Create a revert commit for merge commit `abd7a04`, using its first parent as
the mainline. This removes the online karaoke Demo changes introduced by the
feature branch without rewriting `develop` or discarding the upstream merge at
`2d3a1f6`.

No source files will be edited manually. Git will calculate the inverse of the
feature merge so the restoration remains auditable and recoverable.

## Verification

After the revert:

1. Confirm the online karaoke `Demo/Demo/App` sources are no longer part of the
   restored Demo and the legacy project sources are active again.
2. Run `pod install` for the restored Podfile.
3. Build the Demo for the available iPhone 14 simulator.
4. Install and launch the built app, then capture a screenshot to verify the
   legacy interface is running.
5. Confirm the worktree is clean after committing the revert.
