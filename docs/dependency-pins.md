# Updating pinned build sources

Image scripts download reviewed revisions and verify SHA-256 checksums. This
prevents default-branch changes from silently changing an image build.

To propose updates for all pinned source repositories and Nerd Fonts:

```bash
GITHUB_TOKEN="$(gh auth token)" python3 tools/update-source-pins.py
```

The token is optional but avoids GitHub's low anonymous API rate limit. The
updater downloads every new archive, calculates its checksum, and changes the
corresponding script constants. It does not commit anything.

After reviewing the upstream changes, run:

```bash
shellcheck files/scripts/*.sh tests/*.sh
BLUE9_RUN_NETWORK_TESTS=1 python3 -m unittest discover -s tests -v
podman run --rm --userns=keep-id -v "$PWD:/workspace" -w /workspace \
  ghcr.io/blue-build/cli:v0.9.37 \
  bluebuild generate -o Containerfile recipes/recipe.yml
```

Dependabot separately updates commit-pinned GitHub Actions under
`.github/workflows/`.
