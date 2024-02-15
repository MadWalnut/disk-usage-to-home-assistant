# Disk Usage to Home Assistant

This simple bash script connects to a given server via SSH, gets the filesystem usage via `df` and sends the data to Home Assistant. It includes a [Healthchecks.io](https://healthchecks.io/) integration and the option to notify the user via [Apprise API](https://github.com/caronc/apprise-api) if the storage gets low. Originally written to monitor the storage usage of [Hetzner Storage Boxes](https://www.hetzner.com/storage/storage-box/).

## Installation

### Prerequisites

- Server to monitor with SSH access via SSH key and the 'df' command available (e.g. Hetzner Storage Box)
- Monitoring Server (e.g. generic Linux VM) that will run this script periodically
- Home Assistant Long-Lived Access Token (create one via *user profile -> scroll to bottom*)
- *Optional but recommended: [Healthchecks.io](https://healthchecks.io) generated check URL to monitor this script so you get notified if something stops working*
- *Optional: running instance of [Apprise API](https://apprise.example.com/notify/apprise) or a similar service to notify you if the storage gets low (can also be achieved through a Home Assistant automation though)*

### Script Setup

1. [Save the script](https://raw.githubusercontent.com/MadWalnut/disk-usage-to-home-assistant/master/disk-usage-to-home-assistant.sh) on any Linux server (not the one you want to get the storage stats from).
2. Make the script executable with `chmod +x disk-usage-to-home-assistant.sh`.
3. Edit the config section at the top of the script: `nano disk-usage-to-home-assistant.sh`
4. Test the `ssh` command manually as this is the most likely part of the script to fail if setup incorrectly. This may also be needed once to accept the servers fingerprint. Adapt this command: `ssh URL -l USER -p PORT -i PATH_TO_KEY df -h`
5. Test the whole script manually (`./disk-usage-to-home-assistant.sh`) and see if the values appear in Home Assistant (*Developer Tools -> States -> Filter Entities* for your configured server name).
6. Schedule the script to run regularly, for example via cron (`crontab -e` and then add a line with the schedule and the path to the downloaded script: `0 3 * * * /home/YOURUSER/scripts/disk-usage-to-home-assistant.sh` - [find a schedule](https://crontab.guru) that works for you).

## Optimised for Hetzner Storage Boxes

While optimised for [Hetzner Storage Boxes](https://www.hetzner.com/storage/storage-box/) this script should also work for normal Linux servers. When using Hetzner Storage Boxes remember to enable SSH access in the Hetzner control panel (Hetzner Robot). Use port 23 for SSH access. Beware that Hetzner may temporarily ban your IP if you try to connect with wrong credentials too often.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

Please see [here](LICENSE.md).