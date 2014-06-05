# UTF-8


   

# scope = Dea::Scope.new
# 
# parentComps = []
# subComps = []
# 
# targetComps=[]
# 
# parentComps << "ProcComponent"
# parentComps << "PortalComponent"
# 
# scope.addComponent("AuthComponent" , parentComps,subComps)
# 
# parent=[]
# sub=[]
# 
# parent  << "PortalComponent"
# sub  << "AuthComponents"
# 
# scope.addComponent("ProcComponent" , parent ,sub )
# 
# 
# parentC=[]
# subC=[]
# 
# subC << "AuthComponent"
# subC  << "ProcComponent"
# 
# scope.addComponent("PortalComponent",parentC ,subC )
# 
# targetComps <<"AuthComponent"
# scope.target = targetComps
# scope.isSpecifiedScope = true

#puts scope
# parentComps << ""


### out put

str= "AuthComponent<ProcComponent#AuthComponent<PortalComponent#ProcComponent<PortalComponent#ProcComponent>AuthComponents#PortalComponent>AuthComponent#PortalComponent>ProcComponent#TARGET_COMP@AuthComponent#SCOPE_FLAG&true"

scope2 = Dea::Scope.inverse(str)

# puts scope2.isSpecifiedScope
#
# authParents = scope2.parentComponents["AuthComponent"]
# authSubs = scope2.subComponents["AuthComponents"]
# 
# authParents.each{|p|
  # puts "AuthParent:#{p}"
  # }
 # puts authSubs == nil
# 
# procParents = scope2.parentComponents["ProcComponent"]
# procSubs = scope2.subComponents["ProcComponent"]
# 
# procParents.each{|p|
  # puts "procParent:#{p}"
  # }
# procSubs.each{|s|
   # puts "procSub:#{s}"
  # }  
#   
# portalParents = scope2.parentComponents["PortalComponent"]
# portalSubs = scope2.subComponents["PortalComponent"]
# 
# puts portalParents == nil
# portalSubs.each{|s| puts "portalSub:#{s}" }
# 
# rootComps = scope2.getRootComp("AuthComponent")
# 
# rootComps.each{|r| puts "auth r : #{r}"}
# 
# rootComps = scope2.getRootComp("ProcComponent")
# rootComps.each{|r| puts "proc r : #{r}"}
# 
# rootComps = scope2.getRootComp("PortalComponent")
# 
# rootComps.each{|r| puts "portal r : #{r}"}

#java output
# ProcComponent<PortalComponent#AuthComponent<ProcComponent#AuthComponent<PortalComponent#ProcComponent>AuthComponent#PortalComponent>ProcComponent#PortalComponent>AuthComponent#TARGET_COMP@AuthComponent#SCOPE_FLAG&true






















