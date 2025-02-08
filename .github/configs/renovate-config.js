module.exports = {
    platform: 'github',
    // This ensures that the gitAuthor and gitSignOff fields match
    gitAuthor: 'kubeadapt-renovate[bot] <kubeadapt-renovate[bot]@users.noreply.github.com>',
    autodiscover: false,
    allowPostUpgradeCommandTemplating: true,
    allowedPostUpgradeCommands: [".*"],
    // Enable semantic commit messages
    semanticCommits: 'enabled',
    // Group dependencies by type
    packageRules: [
        {
            matchPackagePatterns: ["^ghcr.io/kubeadapt/"],
            groupName: "kubeadapt components",
            semanticCommitType: "chore",
            semanticCommitScope: "deps"
        }
    ]
}; 