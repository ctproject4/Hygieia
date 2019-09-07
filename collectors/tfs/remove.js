use dashboarddb
db.collectors.remove( { "_class" : "com.capitalone.dashboard.model.TfsCollector" } )
db.builds.remove({"niceName": "tfs/hygieia"})
db.builds.remove({"niceName": "tfs/test"})
db.collector_items.remove( { "description" : "test" })
db.collector_items.remove( { "description" : "hygieia" })
