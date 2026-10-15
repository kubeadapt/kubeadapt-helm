<!--
Commits on main must be signed (repository ruleset). Squash merges are signed by GitHub.
Changes are published automatically when merged to `main`. They are not published on branches.
-->

Checklist:

* [ ] I have bumped the chart version according to semantic versioning (a new minor or major ships fast-only, see [RELEASE-POLICY.md](../docs/RELEASE-POLICY.md))
* [ ] `upgrade-metadata.yaml`: `chartVersion`, `upgradeFrom` (latest release first, released versions only), `channels` and `metadata.releaseNotes` match this version
* [ ] The chart's `RELEASE_NOTES.md` has a `## <version>` section
* [ ] `artifacthub.io/changes` lists only this release's changes
* [ ] `appVersion`, the default image tag and `artifacthub.io/images` agree
* [ ] A chart that depends on a chart in `charts/` pins that chart's current version
* [ ] Any new values are backwards compatible and/or have sensible defaults
* [ ] I have updated the documentation
* [ ] `./scripts/validate-release-metadata.sh` passes locally and the `gate` check is green

Changes:
<!-- Please provide a brief description of the changes in this PR -->
