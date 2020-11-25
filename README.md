# NetworkSniffer
NetworkSniffer will log ALL traffic for any iOS application.

Installation
----------
- Download .deb file package folder
- `SCP` the deb file to your device
- `dpkg -i com.evilpenguin.networksniffer_0.1.0-1+debug_iphoneos-arm`

Usage
----------
- Use the Console.app on macOS
- Filter for `NetworkSniffer`
- Launch the application you want to capture
- Output will be `+[NetworkSniffer] Writing to /var/mobile/Containers/Data/Application/{UUID}/networksniffer.log`
- `tail -f /var/mobile/Containers/Data/Application/{UUID}/networksniffer.log` if you want to watch the log, or simply scp it to your host when done.

Notes
----------
- No cert bypass required
