#!/bin/bash
# munki_mirrors.sh
# 
# script to set munki to different mirror by subnet
# intended for use on rsynced munki servers with reposado on the same server
# best when used as part of a preflight script for munki
# assumes munki is at http://yourserver/munki and reposado at http://yourserver/reposado
# will work on 10.5-10.8
#
# fill in the settings below, GW01 and MS01 should be your main server, where your VPN 
# connections terminate.  GW02 and MS02 next best, etc.
#
# Samuel Keeley
# sam.keeley@me.com
# updated 2012-09-26

defaultsCommand="/usr/bin/defaults"
munkiPlist="/Library/Preferences/ManagedInstalls"
softwareUpdatePlist="/Library/Preferences/com.apple.SoftwareUpdate"

##### FILL IN YOUR INFO BELOW THIS LINE #####

# gateways, fill in and match with munki/reposado servers
GW01="192.168.0.1"
GW02="172.16.0.1"
GW03="10.0.0.1"

# munki/reposado servers, assuming munki and reposado are on the same server, with munki at /munki and reposado at /reposado
MS01="server-gw01.local"
MS02="server-gw02.local"
MS03="server-gw03.local"

# reposado catalogs, change these if you use custom catalogs
REPML="index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
REPLION="index-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
REPSL="index-leopard-snowleopard.merged-1.sucatalog"
REPLEP="index-leopard.merged-1.sucatalog"

##### FILL IN YOUR INFO ABOVE THIS LINE #####

MS01RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS01}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS01 HTTP $MS01RESP $MS01
MS02RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS02}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS02 HTTP $MS02RESP $MS02
MS03RESP=`curl -sL -w "%{http_code} %{url_effective}\\n" "http://${MS03}/munki/manifests/client_manifest" -o /dev/null | awk '{print $1;}'`
echo MS03 HTTP $MS03RESP $MS03

# get en0 gateway - ethernet 1
EN0GW=`ifconfig en0 | grep 'inet ' | awk '{print $6;}'`
echo en0 gw $EN0GW

# get en1 gateway - ethernet 2 on mac pro or wifi 
EN1GW=`ifconfig en1 | grep 'inet ' | awk '{print $6;}'`
echo en1 gw $EN1GW

# get en2 gateway - wifi on mac pro or thunderbolt ethernet
EN2GW=`ifconfig en2 | grep 'inet ' | awk '{print $6;}'`
echo en2 gw $EN2GW

# get OS, set reposado catalog

echo OS is $OSTYPE

echo Using catalog:

if [[ "$OSTYPE" == "darwin12" ]] ; then
	# mountain lion
	REPCL="$REPML"
	echo $REPCL
elif [[ "$OSTYPE" == "darwin11" ]] ; then
	# lion
	REPCL="$REPLION"
	echo $REPCL
elif [[ "$OSTYPE" == "darwin10" ]] ; then
	# snow leopard
	REPCL="$REPSL"
	echo $REPCL
elif [[ "$OSTYPE" == "darwin9" ]] ; then
	# leopard
	REPCL="$REPLEP"
	echo $REPCL
fi

# work through servers

if [[ "$MS01RESP" == "200" ]] && ( [[ "$EN0GW" == "$GW01" ]] || [[ "$EN1GW" == "$GW01" ]] || [[ "$EN2GW" == "$GW01" ]] ) ; then
	echo Setting server to $MS01
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS01}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS01}/munki"
elif [[ "$MS02RESP" == "200" ]] && ( [[ "$EN0GW" == "$GW02" ]] || [[ "$EN1GW" == "$GW02" ]] || [[ "$EN2GW" == "$GW02" ]] ) ; then
	echo Setting server to $MS02
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS02}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS02}/munki"
elif [[ "$MS03RESP" == "200" ]] && ( [[ "$EN0GW" == "$GW03" ]] || [[ "$EN1GW" == "$GW03" ]] || [[ "$EN2GW" == "$GW03" ]] ) ; then
	echo Setting server to $MS03
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS03}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS03}/munki"
elif [[ "$MS01RESP" == "200" ]] ; then
	echo VPN or unknown gateway, defaulting to $MS01
	echo Setting server to $MS01
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS01}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS01}/munki"
elif [[ "$MS02RESP" == "200" ]] ; then
	echo VPN or unknown gateway, defaulting to $MS02 after $MS01 failed to respond
	echo Setting server to $MS02
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS02}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS02}/munki"
elif [[ "$MS03RESP" == "200" ]] ; then
	echo VPN or unknown gateway, defaulting to $MS03 after $MS01 and $MS02 failed to respond
	echo Setting server to $MS03
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS03}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS03}/munki"
else
	echo Contact with all servers failed, defaulting to $MS01 
	echo Setting server to $MS01
	${defaultsCommand} write "$softwareUpdatePlist" CatalogURL "http://${MS01}/reposado/content/catalogs/others/${REPCL}"
	${defaultsCommand} write "$munkiPlist" SoftwareRepoURL "http://${MS01}/munki"
fi

echo Software Update CatalogURL:
${defaultsCommand} read "$softwareUpdatePlist" CatalogURL

echo Munki SoftwareRepoURL:
${defaultsCommand} read "$munkiPlist" SoftwareRepoURL

exit 0