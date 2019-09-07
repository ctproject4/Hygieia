use dashboarddb
db.collectors.find( { "lastExecuted" : NumberLong("LASTEXECUTEDTIME") }, {"_id" : 1 } )
