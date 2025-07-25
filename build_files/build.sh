#!/bin/bash
# vim:foldmethod=marker:foldlevel=0

set -ouex pipefail

### Install packages {{{

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y \
  ansible \
  foot \
  papirus-icon-theme

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# }}}

#### Enable a System Unit File {{{

# systemctl enable podman.socket

# }}}

#### Nix dir setup {{{
# See https://github.com/DeterminateSystems/nix-installer/issues/1445
install -d -m 0755 /nix

# }}}

#### Cleanup {{{

# Clean package manager cache
dnf5 clean all

# Clean temporary files
rm -rf /tmp/*
# shellcheck disable=SC2115
rm -rf /var/*
rm -rf /usr/etc

# Restore and setup directories
mkdir -p /tmp
install -d /var/tmp -m 1777 /var/tmp

# }}}
