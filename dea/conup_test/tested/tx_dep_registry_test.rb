# UTF-8

require "../conup/tx_dep_registry"

futureComps = Array.new
futureComps << "ProcComponent"
futureComps << "PortalComponent"

 
pastComps = Array.new
pastComps << "AuthComponent"
pastComps << "ProcComponent"

tx_dep = Dea::TxDep.new(futureComps,pastComps)

tx_dep2 = Dea::TxDep.new(pastComps,futureComps)

registry = Dea::TxDepRegistry.new

puts registry

puts registry.getLocalDep("abc") == nil

registry.addLocalDep("abc",tx_dep)
registry.addLocalDep("gbc",tx_dep2)

# puts registry
puts registry.getLocalDep("abc")  
puts
puts registry.getLocalDep("gbc")
# h = {}
# h["abc"] = tx_dep2
# h["def"] =2 
# 
# puts h["abc"]


# puts registry.contains("agc")
# puts registry.contains("abc")
# 
# registry.removeLocalDep("abc")
# puts registry

### out put

#<Dea::TxDepRegistry:0x000000023de468>

# id: abc ,  dep: past:ProcComponent,PortalComponent,
# future:AuthComponent,ProcComponent, 
# ---
#<Dea::TxDepRegistry:0x000000023de468>
# false
# true
#<Dea::TxDepRegistry:0x000000023de468>
