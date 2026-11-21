# Lenovo Legion extras

Not needed to copy the desktop. These are fixes for my laptop and are kept out of the repo because they depend on the machine:

- Speaker amp fix (TAS2781) and mic gain, run as a systemd service at boot and resume.
- Fan and power-profile control through the `legion_laptop` DKMS module, signed with an enrolled Secure Boot key.
- Quiet profile disables turbo on this firmware; Balanced re-enables it.

If you have a Legion, search for the `legion-linux` project and the `tas2781` fix for your model.
