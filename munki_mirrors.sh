#!/bin/bash
# munki_mirrors.sh
# 
# preflight script for munki for when you have different munki and SUS/reposado servers by subnet
#
# Samuel Keeley
# sam.keeley@me.com
# 2012-09-24

defaultsCommand="/usr/bin/defaults"
munkiPlist="/Library/Preferences/ManagedInstalls"
softwareUpdatePlist="/Library/Preferences/com.apple.SoftwareUpdate"

##### FILL IN YOUR INFO BELOW THIS LINE #####

# gateways, fill in and match with munki/reposado servers
GW01="192.168.1.1"
GW02="172.16.0.1"
GW03="10.0.0.1"

# munki/reposado servers, assuming munki and reposado are on the same server, with munki at /munki and reposado at /reposado
MS01="server01.yourcompany.com"
MS02="server02.yourcompany.com"
MS03="server03.yourcompany.com"

# reposado catalogs, change these if you use custom catalogs
REPML="index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
REPLION="index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
REPSL="index-snowleopard-leopard.merged-1.sucatalog"

##### FILL IN YOUR INFO ABOVE THIS LINE #####

MS01RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS01}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS01RESP: $MS01RESP $MS01
MS02RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS02}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS02RESP: $MS02RESP $MS02
MS03RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS03}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS03RESP: $MS03RESP $MS03

# get en0 gateway - ethernet (hopefully)
EN0GW=`ifconfig en0 | grep 'inet ' | awk '{print $6;}'`
echo EN0GW: $EN0GW

# get en1 gateway - ethernet 2 on mac pro, wi-fi on everything else
EN1GW=`ifconfig en1 | grep 'inet ' | awk '{print $6;}'`
echo EN1GW: $EN1GW

# get en2 gateway - wifi on mac pro
EN2GW=`ifconfig en2 | grep 'inet ' | awk '{print $6;}'`
echo EN2GW: $EN2GW

# get OS, set reposado catalog
if [[ "$OSTYPE" == "darwin12" ]] ; then
	# mountain lion
	REPCL="$REPML"
	echo $REPCL
fi 
if [[ "$OSTYPE" == "darwin11" ]] ; then
	# lion
	REPCL="$REPLION"
	echo $REPCL
fi
if [[ "$OSTYPE" == "darwin10" ]] ; then
	# snow leopard
	REPCL="$REPSL"
	echo $REPCL
fi

# work through servers

if [[ "$MS01RESP" == "200" ]] && [[ "$EN0GW" == "$GW01" ]] || [[ "$EN1GW" == "$GW01" ]] || [[ "$EN2GW" == "$GW01" ]] ; then
	echo Setting server to $MS01
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS01}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS01}/munki"
elif [[ "$MS02RESP" == "200" ]] && [[ "$EN0GW" == "$GW02" ]] || [[ "$EN1GW" == "$GW02" ]] || [[ "$EN2GW" == "$GW02" ]] ; then
	echo Setting server to $MS02
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS02}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS02}/munki"
elif [[ "$MS03RESP" == "200" ]] && [[ "$EN0GW" == "$GW03" ]] || [[ "$EN1GW" == "$GW03" ]] || [[ "$EN2GW" == "$GW03" ]] ; then
	echo Setting server to $MS03
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS03}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS03}/munki"
else
	echo No servers responded or on VPN, defaulting to $MS01
	echo Setting server to $MS01
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS01}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS01}/munki"
fi
exit 0