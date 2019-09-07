#!/bin/bash

update_collector_epoch() {

	cur_datetime=`date "+%D %T"`
	temp="`date -d "$cur_datetime" "+%s"`000"
#	echo $temp
	sed -i "s/LASTEXECUTEDTIME/$temp/" collector_collection 
	sed -i "s/LASTEXECUTEDTIME/$temp/" collectorid.js 

}

update_collector_epoch
mongoimport --db dashboarddb --collection collectors --file collector_collection
mongo < collectorid.js > id

collector_collection_oid=`awk 'NR==5' id | cut -d ':' -f2 | cut -d '"' -f2`
#echo $collector_collection_oid
sed -i "s/COLLECTORID/$collector_collection_oid/" collectoritemid.js

sed -i "s/$temp/LASTEXECUTEDTIME/" collector_collection
sed -i "s/$temp/LASTEXECUTEDTIME/" collectorid.js

# curl -u username:accesstoken url/repo/_apis/projects?api-version=version

curl -u ajay.rikame@citiustech.com:mlzpzhmp2aiwqx4ausv3anatsqujlv3b767nlkucerkvdi7qmdna https://dev.azure.com/ajayrikame0046/_apis/projects?api-version=2.0 > project_api

count=`awk -F '"count":' {'print $2'} project_temp | awk -F "," {'print $1'}`
sed -i -e $'s/},/\\\n/g' project_api


sed -i "s/COLLECTORCOLLECTIONOID/$collector_collection_oid/" collector_items_collection

#sed -i "s/TFSURL/$url/" collector_items_collection
#sed -i "s/TFSURL/$url/" build_collection
i=1
while [ $count -gt 0 ]
do

name=`awk -F '"name":' {'print $2'} project_api | awk -F "," {'print $1'} | awk -F '"' {'print $2'} | awk "NR==$i"`
sed -i "s/PROJECTNAME/$name/" collectoritemid.js

time=`awk -F '"lastUpdateTime":' {'print $2'} project_api | awk -F "," {'print $1'} | awk -F '"' {'print $2'} | awk "NR==$i"`
d=$(date -d `echo $time | cut -d 'T' -f1` "+%D")
t=$(date -d `echo $time | cut -d 'T' -f2 | cut -d 'Z' -f1` "+%T")
collect_temp="`date -d "$d $t" "+%s"`000"
collect_temp_f=`expr $collect_temp + 19800000`
#echo $name
sed -i "s/PROJECTNAME/$name/" collector_items_collection
sed -i "s/TIME/$collect_temp_f/" collector_items_collection
mongoimport --db dashboarddb --collection collector_items --file collector_items_collection

mongo < collectoritemid.js > itemid
coll_item_id=`awk 'NR==5' itemid | cut -d ':' -f2 | cut -d '"' -f2`

sed -i "s/COLLECTORITEMCOLLECTIONOID/$coll_item_id/" build_collection
sed -i "s/PROJECTNAME/$name/" build_collection


curl -u ajay.rikame@citiustech.com:mlzpzhmp2aiwqx4ausv3anatsqujlv3b767nlkucerkvdi7qmdna https://dev.azure.com/ajayrikame0046/$name/_apis/build/builds?api-version=5.0 > build_api

sed -i -e $'s/},/\\\n/g' build_api

count_build=`awk -F '"count":' {'print $2'} build_api | awk -F "," {'print $1'}`
while [ $count_build -gt 0 ]
do

number=`grep '"buildNumber":' build_api | awk -F '"id":' {'print $2'} | awk -F "," {'print $1'} | awk "NR==$count_build"`

startedby=`grep '"requestedBy":' build_api | awk -F '"displayName":"' {'print $2'} | awk -F '"' {'print $1'} | awk "NR==$count_build"`

jobstatus=`grep '"result":' build_api | awk -F '"result":"' {'print $2'} | awk -F '"' {'print $1'} | awk "NR==$count_build"`
if [ $jobstatus == 'succeeded' ]; 
	then jobstatus='Success'
fi
if [ $jobstatus == 'failed' ];
        then jobstatus='Failure'
fi

current_datetime=`date "+%D %T"`
timestamp="`date -d "$current_datetime" "+%s"`000"

starttime=`grep "startTime" build_api | awk -F '"startTime":"' '{print $2}' | awk -F '"' '{print $1}' | awk "NR==$count_build"`
d=$(date -d `echo $starttime | cut -d 'T' -f1` "+%D")
t=$(date -d `echo $starttime | cut -d 'T' -f2 | cut -d 'Z' -f1` "+%T")
collect_temp="`date -d "$d $t" "+%s"`000"
starttime=`expr $collect_temp + 19800000`

finishtime=`grep "finishTime" build_api | awk -F '"finishTime":"' '{print $2}' | awk -F '"' '{print $1}' | awk "NR==$count_build"`
d=$(date -d `echo $finishtime | cut -d 'T' -f1` "+%D")
t=$(date -d `echo $finishtime | cut -d 'T' -f2 | cut -d 'Z' -f1` "+%T")
collect_temp="`date -d "$d $t" "+%s"`000"
finishtime=`expr $collect_temp + 19800000`

duration=`expr $finishtime - $starttime`

sed -i "s/NUMBER/$number/" build_collection
sed -i "s/STARTEDBY/$startedby/" build_collection
sed -i "s/STATUS/$jobstatus/" build_collection
sed -i "s/TIMESTAMP/$timestamp/" build_collection
sed -i "s/STARTTIME/$starttime/" build_collection
sed -i "s/ENDTIME/$finishtime/" build_collection
sed -i "s/DURATION/$duration/" build_collection

mongoimport --db dashboarddb --collection builds --file build_collection

sed -i "3s/$number/NUMBER/" build_collection
sed -i "s/$startedby/STARTEDBY/" build_collection
sed -i "s/$jobstatus/STATUS/" build_collection
sed -i "s/$timestamp/TIMESTAMP/" build_collection
sed -i "s/$starttime/STARTTIME/" build_collection
sed -i "s/$finishtime/ENDTIME/" build_collection
sed -i "s/$duration/DURATION/" build_collection
((count_build--))

done

sed -i "s/$name/PROJECTNAME/" collector_items_collection
sed -i "s/$name/PROJECTNAME/" build_collection
sed -i "s/$coll_item_id/COLLECTORITEMCOLLECTIONOID/" build_collection
sed -i "s/$collect_temp_f/TIME/" collector_items_collection

sed -i "s/$name/PROJECTNAME/" collectoritemid.js

((i++))
((count--))

done
sed -i "s/$collector_collection_oid/COLLECTORCOLLECTIONOID/" collector_items_collection
sed -i "s/$collector_collection_oid/COLLECTORID/" collectoritemid.js
