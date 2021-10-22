# XRecon

Automated reconnaissance tool for Penetration Testing

> Inspired by @hmaverickadams and @Gr1mmie

### Installation

Just run this one-liner from terminal:
```bash
git clone https://github.com/johar-raza/xrecon.git && cd xrecon && chmod +x recon.sh
```

### Usage
The scripts takes one URL as the only argument.

```bash
./recon.sh <URL>
```

### Dependencies

This script requires the following tools to run:
- [assetfinder](https://github.com/tomnomnom/assetfinder)
- [amass](https://github.com/OWASP/Amass)
- [httprobe](https://github.com/tomnomnom/httprobe)
- [subjack](https://github.com/haccer/subjack)
- [waybackurls](https://github.com/tomnomnom/waybackurls)
- [gowitness](https://github.com/sensepost/gowitness)
- [nmap](https://nmap.org/)

**Note:** The script has been tested on Kali linux
