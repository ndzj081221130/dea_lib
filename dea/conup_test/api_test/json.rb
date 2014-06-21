#UTF-8

require_relative "../../conup/client_sync"
require_relative "../../conup/node_mgr"
require 'json'
require 'set'
# test = Set.new
# test << "1234"
# test << "1339d740-03b8-4d27-9b3d-08058d2541c3"
# puts test.to_a.to_json 
# {"RootTx"=>"1234"}
# {"RootTx":"1234"}
#{"RootTx":"","ParentTx":"","ParentPort":"","ParentName":"","SubPort":"8002","SubName":""}
 

# puts @json
# puts @json.class

# @json.each{|ai|
  # puts "ai = #{ai}"
  # }

  # handle = "{\"RootTx\"=>\"09cb5cf5-a4dd-40f9-98d7-963201c9f3a9\", "+
        # "\"ParentTx\"=>\"09cb5cf5-a4dd-40f9-98d7-963201c9f3a9\", \"ParentPort\"=>\"8002\"," +
        # " \"ParentName\"=>\"CallComponent\", \"SubPort\"=>\"8001\", \"SubName\"=>\"HelloworldComponent\"," +
        # " \"InvocationCtx\"=>\"\"INVOCATION_CONTEXT[09cb5cf5-a4dd-40f9-98d7-963201c9f3a9:CallComponent,09cb5cf5-a4dd-40f9-98d7-963201c9f3a9:CallComponent,FAKE_TX_ID7f011ec4-3efc-4039-ae1f-4d52750d0c1f:HelloworldComponent,CallComponent:09cb5cf5-a4dd-40f9-98d7-963201c9f3a9]\"\"}"
     
     
     
# {"RootTx":"09cb5cf5-a4dd-40f9-98d7-963201c9f3a9",
  # "ParentTx":"09cb5cf5-a4dd-40f9-98d7-963201c9f3a9",
  # "ParentPort":"8002","ParentName":"CallComponent",
  # "SubPort":"8001","SubName":"HelloworldComponent",
  # "InvocationCtx":"\"INVOCATION_CONTEXT[09cb5cf5-a4dd-40f9-98d7-963201c9f3a9:CallComponent,09cb5cf5-a4dd-40f9-98d7-963201c9f3a9:CallComponent,FAKE_TX_ID7f011ec4-3efc-4039-ae1f-4d52750d0c1f:HelloworldComponent,CallComponent:09cb5cf5-a4dd-40f9-98d7-963201c9f3a9]\""}

     
     
     
     
     handle = "{\"RootTx\":\"\",\"ParentTx\":\"\",\"ParentPort\":\"\",\"ParentName\":\"\",\"SubPort\":\"8000\"," +
       "\"SubName\":\"\",\"InvocationCtx\":\"INVOCATION_CONTEXT[09c]\"           \"}"
      json = JSON::parse(handle)
        parentPort = json["ParentPort"]
        parentName = json["ParentName"]
        parentTx = json["ParentTx"]
        rootTx = json["RootTx"]
        subPort = json["SubPort"]
        subName = json["SubName"]
        invocation = json["InvocationCtx"]
        puts subPort
        puts rootTx
        puts invocation
        puts parentName
        puts parentPort
        
        
        
        
        
        
        
        
        
        
     #attributes = "{\"InstanceId\":\"40c088c7b61e286b09829745ddc17ab04d858044f7a615d88a792d955623a331\"}"
      # begin
        # json =  Echo.translate_attributes(attributes)
      # rescue Exception => e
        # puts "Index Error"
      # end