#!/bin/bash

url=$1

# Check if the required tools are installed
if [ ! -x "$(command -v assetfinder)" ];then
	echo "[-] Assetfinder required to run the script. "
	exit 1
fi

if [ ! -x "$(command -v amass)" ];then
	echo "[-] Amass required to run the script. "
	exit 1
fi

if [ ! -x "$(command -v httprobe)" ];then
	echo "[-] Httprobe not installed. "
	exit 1
fi

if [ ! -x "$(command -v nmap)" ];then
	echo "[-] Nmap required to run the script. "
	exit 1
fi

if [ ! -x "$(command -v waybackurls)" ];then
	echo "[-] Waybackurls required to run the script. "
	exit 1
fi

if [ ! -x "$(command -v subjack)" ];then
	echo "[-] Subjack required to run the script. "
	exit 1
fi

if [ ! -x "$(command -v gowitness)" ];then
	echo "[-] Gowitness required to run the script. "
	exit 1
fi

# Check if the required directories/files exist
if [ ! -d "$url" ];then
	mkdir $url
fi

if [ ! -d "$url/recon" ];then
	mkdir $url/recon
	touch $url/recon/subdomains.txt
fi	

if [ ! -d "$url/recon/httprobe" ];then
	mkdir $url/recon/httprobe
	touch $url/recon/httprobe/alive.txt
fi

if [ ! -d "$url/recon/gowitness" ];then
	mkdir $url/recon/gowitness
fi

if [ ! -d "$url/recon/scans" ];then
	mkdir $url/recon/scans
fi

if [ ! -d "$url/recon/potential_takeovers" ];then
	mkdir $url/recon/potential_takeovers
	touch $url/recon/potential_takeovers/potential_takeovers.txt
fi

if [ ! -d "$url/recon/wayback" ];then
	mkdir $url/recon/wayback
	mkdir $url/recon/wayback/params
	mkdir $url/recon/wayback/extensions
fi

# Recon
echo "[+] Harvesting subdomains with assetfinder..."
assetfinder $url >> $url/recon/assetfinder.txt
cat $url/recon/assetfinder.txt | grep $1 >> $url/recon/subdomains.txt
rm $url/recon/assetfinder.txt

echo ""

echo "[+] Harvesting subdomains with amass..."
amass enum -d $url | sort -u >> $url/recon/subdomains.txt

# Keep only unique subdomains
sort -u $url/recon/subdomains.txt -o $url/recon/subdomains.txt

echo ""

echo "[+] Probing for alive domains..."
cat $url/recon/subdomains.txt | sort -u | httprobe | sort -u >> $url/recon/httprobe/alive.txt
cat $url/recon/subdomains.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' | sort -u >> $url/recon/httprobe/https.txt

echo ""

echo "[+] Checking for possible subdomain takeovers..."
subjack -a -w $url/recon/subdomains.txt -t 100 -timeout 30 -ssl -c ~/go/pkg/mod/github.com/haccer/subjack@v0.0.0-20201112041112-49c51e57deab/fingerprints.json -v 3 -o $url/recon/potential_takeovers/potential_takeovers.txt

echo ""

echo "[+] Scraping wayback data..."
cat $url/recon/subdomains.txt | waybackurls | sort -u >> $url/recon/wayback/wayback_output.txt

echo ""

echo "[+] Pulling and compiling all possible params found in wayback data..."
cat $url/recon/wayback/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $url/recon/wayback/params/wayback_params.txt
#for line in $(cat $url/recon/wayback/params/wayback_params.txt);do echo $line'=';done

echo ""

echo "[+] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
for line in $(cat $url/recon/wayback/wayback_output.txt);do
    ext="${line##*.}"
    if [[ "$ext" == "js" ]]; then
        echo $line | sort -u >>  $url/recon/wayback/extensions/js.txt
    fi
    if [[ "$ext" == "html" ]];then
        echo $line | sort -u >> $url/recon/wayback/extensions/jsp.txt
    fi
    if [[ "$ext" == "json" ]];then
        echo $line | sort -u >> $url/recon/wayback/extensions/json.txt
    fi
    if [[ "$ext" == "php" ]];then
        echo $line | sort -u >> $url/recon/wayback/extensions/php.txt
    fi
    if [[ "$ext" == "aspx" ]];then
        echo $line | sort -u >> $url/recon/wayback/extensions/aspx.txt
    fi
done

echo ""

echo "[+] Running gowitness against all compiled domains"
gowitness file -Ff $url/recon/httprobe/https.txt -P $url/recon/gowitness --timeout 15

echo ""

echo "[+] Scanning for open ports..."
nmap -iL $url/recon/httprobe/https.txt -T4 -oA $url/recon/scans/scans

echo ""
echo "[!] Output saved in $url/recon"
