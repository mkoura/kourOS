# kourOS

This repo was built on the [Universal Blue Image Template](https://github.com/ublue-os/image-template) and slightly modified for my needs, mostly just to create `/nix` in Bluefin.

## Rebasing

You can rebase to an **kourOS** image using the following:

```console
sudo bootc switch --enforce-container-sigpolicy ghcr.io/mkoura/kouros:latest
```
