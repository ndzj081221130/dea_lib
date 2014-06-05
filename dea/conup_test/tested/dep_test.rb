# UTF-8

require_relative "../../conup/dep"
require "set"


type = ">>>"
rootTx="avcf-dfsff-sdre"
srcComp = "ProcComponent"
targetComp ="AuthComponent"
sourceService = "sSer"
targetService ="targSer"
dep = Dea::Dependence.new(type,rootTx,srcComp,targetComp,sourceService,targetService)

puts dep
dep2 = Dea::Dependence.createByDep(dep)
puts dep2

dep3 = Dea::Dependence.new(type,rootTx,targetComp,srcComp,sourceService,targetService)
puts dep3
puts dep ==  dep2

puts dep  > dep3


set1 =  Set.new

set1 << dep

set1 << dep2
puts
puts "-----------------------------------------------\n"
set1.each{|de|
puts de
}