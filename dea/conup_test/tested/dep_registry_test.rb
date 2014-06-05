# UTF-8
require "../conup/dep"
require "../conup/dep_registry"

type = "FUTURE_DEP"
rootTx="avcf-dfsff-sdre"
srcComp = "ProcComponent"
targetComp ="AuthComponent"
sourceService = "sSer"
targetService ="targSer"
dep = Dea::Dependence.new(type,rootTx,srcComp,targetComp,sourceService,targetService)

#puts dep
dep2 = Dea::Dependence.createByDep(dep)
#puts dep2

dep3 = Dea::Dependence.new("PAST_DEP",rootTx,targetComp,srcComp,sourceService,targetService)
#puts dep3

registry = Dea::DependenceRegistry.new

registry.addDependence(dep)
registry.addDependence(dep2)
registry.addDependence(dep3)

puts registry

puts registry.contain(dep)
puts registry.size
registry.addDependence(Dea::Dependence.new("PAST_DEP","abc-cdd-ffd","PortalComponent","AuthComponent","a","b"))


puts
arr = registry.getDependencesViaRootTransaction(rootTx)

arr.each{|a|
  puts "tx : #{a}"
  }


arr = registry.getDependencesViaType(">>>")

arr.each{|a|
  puts "type : #{a}"
  }
  
puts

arr = registry.getDependencesViaTargetComponent(targetComp)

arr.each{|a|
  puts "targetComp : #{a}"
  }
  
puts

arr = registry.getDependencesViaSourceService(sourceService)

arr.each{|a|
  puts "ss : #{a}"
  }
  
arr = registry.getDependencesViaTargetService(targetService)

arr.each{|a|
  puts "ts : #{a}"
  }
  

### output

# ---dep_registry_begin----
# dep = FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# dep = FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# dep = PAST_DEP,avcf-dfsff-sdre,src:AuthComponent,target:ProcComponent,ss:sSer, ts:targSer
# 
# ---dep_registry_end----
# true
# 3
# 
# tx : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# tx : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# tx : PAST_DEP,avcf-dfsff-sdre,src:AuthComponent,target:ProcComponent,ss:sSer, ts:targSer
# 
# targetComp : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# targetComp : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# targetComp : PAST_DEP,abc-cdd-ffd,src:PortalComponent,target:AuthComponent,ss:a, ts:b
# 
# ss : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# ss : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# ss : PAST_DEP,avcf-dfsff-sdre,src:AuthComponent,target:ProcComponent,ss:sSer, ts:targSer
# ts : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# ts : FUTURE_DEP,avcf-dfsff-sdre,src:ProcComponent,target:AuthComponent,ss:sSer, ts:targSer
# ts : PAST_DEP,avcf-dfsff-sdre,src:AuthComponent,target:ProcComponent,ss:sSer, ts:targSer
