#!/bin/bash
# vim:foldmethod=marker:foldlevel=0

set -ouex pipefail

TAG="${1:?"Tag needs to be provided"}"

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages {{{

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

LAYERED_PACKAGES=(
  ansible
  bat
  expect
  fd-find
  foot
  fzf
  jq
  mc
  mosh
  neovim
  nmap
  papirus-icon-theme
  tcpdump
  tmux
  wireshark
  wireshark-cli
  zoxide
)

LAYERED_PACKAGES_LAPTOP=(
  kismet
)

LAYERED_PACKAGES_WORKSTATION=(
  dracut-sshd
)

case "$TAG" in
  laptop)
    dnf5 install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}" "${LAYERED_PACKAGES_LAPTOP[@]}"
    ;;
  workstation)
    dnf5 -y copr enable gsauthof/dracut-sshd
    dnf5 install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}" "${LAYERED_PACKAGES_WORKSTATION[@]}"
    dnf5 -y copr disable gsauthof/dracut-sshd
    ;;
  silverblue)
    dnf5 install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"
    ;;
  *)
    echo "Unknown tag: $TAG" >&2
    exit 1
    ;;
esac

# }}}

### Container signature verification {{{

# CI signs every published image, but that is worth nothing unless the
# installed system actually checks the signature. Teach it to, by pinning our
# repo to our public key.
#
# Note the consequence: once this is in place, an image published without a
# valid signature cannot be pulled by `bootc upgrade`.

# shellcheck source=/dev/null
. /ctx/kouros.env

SIGNED_REPO="ghcr.io/${REPO_ORGANIZATION,,}/${IMAGE_NAME,,}"
KEY_PATH="/etc/pki/containers/${IMAGE_NAME,,}.pub"
POLICY="/etc/containers/policy.json"

install -D -m 0644 /ctx/cosign.pub "$KEY_PATH"

# cosign publishes signatures as sigstore attachments rather than as
# traditional detached signatures, so they have to be looked for.
install -d -m 0755 /etc/containers/registries.d
cat > "/etc/containers/registries.d/${IMAGE_NAME,,}.yaml" <<EOF
docker:
  ${SIGNED_REPO}:
    use-sigstore-attachments: true
EOF

# Merge into the base image's policy instead of replacing it: the base ships
# its own entries for the ublue repos, and dropping those would stop the
# machine from pulling its own parent image.
if [ ! -f "$POLICY" ]; then
  echo "Expected $POLICY in the base image, refusing to guess" >&2
  exit 1
fi

POLICY_TMP="$(mktemp)"
jq --arg repo "$SIGNED_REPO" --arg key "$KEY_PATH" '
  .transports.docker[$repo] = [{
    "type": "sigstoreSigned",
    "keyPath": $key,
    "signedIdentity": {"type": "matchRepository"}
  }]
' "$POLICY" > "$POLICY_TMP"

# Never install a policy we cannot read back; an unparseable policy.json
# blocks every image pull, including the recovery one.
jq -e . "$POLICY_TMP" > /dev/null
install -D -m 0644 "$POLICY_TMP" "$POLICY"
rm -f "$POLICY_TMP"

# }}}

### Enable a System Unit File {{{

# systemctl enable podman.socket

# }}}

### Nix dir setup {{{
# See https://github.com/DeterminateSystems/nix-installer/issues/1445
install -d -m 0755 /nix

# }}}

### Generate initramfs {{{

case "$TAG" in
  workstation)
    # Cannot do initramfs generation with dracut-sshd at this point, because SSH host key
    # doesn't exist yet. Therefore it's commented out.
    #
    # KERNEL_VERSION="$(rpm -q --queryformat="%{EVR}.%{ARCH}" kernel-core)"
    #
    # export DRACUT_NO_XATTR=1
    # /usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/lib/modules/$KERNEL_VERSION/initramfs.img"
    #
    # chmod 0600 /lib/modules/"$KERNEL_VERSION"/initramfs.img
    # ostree container commit
esac

# }}}

### Cleanup {{{

# Clean package manager cache
dnf5 clean all
rm -rf /var/lib/dnf

# }}}
