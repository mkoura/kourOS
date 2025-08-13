# kourOS

This repo was built on the [Universal Blue Image Template](https://github.com/ublue-os/image-template).

The scheduled build rebuilds images only when there were changes to the base image.

## Rebasing

You can rebase to **kourOS** images using one of the following:

```console
sudo bootc switch --enforce-container-sigpolicy ghcr.io/mkoura/kouros:laptop
sudo bootc switch --enforce-container-sigpolicy ghcr.io/mkoura/kouros:workstation
sudo bootc switch --enforce-container-sigpolicy ghcr.io/mkoura/kouros:silverblue
```
