#!/bin/bash

# Shortcomings:
# This script is based on the Synology Download Station V3 API published at
# http://download.synology.com/download/other/Synology_Download_Station_Official_API_V3.pdf
# NOTE: A newer version of this guide is here:
# http://download.synology.com/download/Document/DeveloperGuide/Synology_Download_Station_Web_API.pdf
# but does not take some of it's recommendations, specifically that of checking the location
# of APIs from the query. It assumes these APIs are in fixed locations.

# URL of the Syno including HTTP port for API authentication.
# No trailing slash
SYNO="http://diskstation:5000"

# Username to auth
USER="mike"

# Password for the above user
# Possible issue if it contains the & character
PASS="password"

# File to parse URLs from
# Each URL should be on a seperate line
# Possible issue if it contains the & character
FILE="./urls.txt"

# Verify API with DM
echo -n "Verifying API ... "
RESULT=`wget -qO - "$SYNO/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth,SYNO.DownloadStation.Task" | grep '"success":true'`

if [ "$RESULT" != "" ]
then
 echo "ok"
 # Authenticate to DM
 echo -n "Authenticating to API ... "
 SID=`wget -qO - "$SYNO/webapi/auth.cgi?api=SYNO.API.Auth&version=2&method=login&account=$USER&passwd=$PASS&session=DownloadStation&format=sid" | grep 'sid' | awk -F\" '{print $6}'`
 if [ "$SID" != "" ]
 then
 echo "ok"
 # Session ID obtained in SID
 # Start parsing the file list
 while read line
 do
 # a line has been read in as $line
 # send this to the Syno DM
 echo -n "Sending task to DM: $line ... "
 RESULT=`wget -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=create&uri=$line&_sid=$SID" "$SYNO/webapi/DownloadStation/task.cgi" grep '"success":true'`
 if [ "$RESULT" != "" ]
 then
 echo "ok"
 else
 echo "fail"
 fi
 done < $FILE
 # Done. Log out (invalidate SID)
 # Note: Since logging out, don't really care to check the response.
 echo -n "Logging out of API ... "
 wget -qO - "$SYNO/webapi/auth.cgi?api=SYNO.API.Auth&version=1&method=logout&session=DownloadStation" > /dev/null
 echo "done."
 else
 echo "fail"
 fi
else
 echo "fail"
fi
