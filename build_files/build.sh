#!/bin/bash
# vim:foldmethod=marker:foldlevel=0

set -ouex pipefail

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
  foot
  papirus-icon-theme
)

case "$TAG" in
  workstation)
    dnf5 -y copr enable gsauthof/dracut-sshd
    dnf5 install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}" dracut-sshd
    dnf5 -y copr disable gsauthof/dracut-sshd
    ;;
  *)
    dnf5 install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"
esac

ostree container commit

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
