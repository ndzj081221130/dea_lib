# UTF-8

require "../conup/tx_context"
require "../conup/scope"


# txCtx = Dea::TxContext.new
# invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53"
# 
# txCtx.invocationSequence = invocationSequence
# 
# #puts invocationSequence
# 
# str= "AuthComponent<ProcComponent#"+
# "AuthComponent<PortalComponent#ProcComponent<PortalComponent#ProcComponent>AuthComponents#"+
# "PortalComponent>AuthComponent#PortalComponent>ProcComponent#TARGET_COMP@AuthComponent#SCOPE_FLAG&true"
# 
# scope2 = Dea::Scope.inverse(str)
# 
# tc = Dea::TxContext.new
# 
# tc.currentTx="657c-4791-4791-8fae-f1cda8d2dd53"
# tc.hostComponent="AuthComponent"
# tc.parentComponent="ProcComponent"
# tc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53"
# tc.rootComponent="PortalComponent"
# tc.rootTx="a358ab2d-cf1a-4e7e-857a-d89c2db40102"

# puts "specified:#{scope2.isSpecifiedScope}"
# puts tc.getProxyRootTxId(scope2)
#a358ab2d-cf1a-4e7e-857a-d89c2db40102

  # scope =  Dea::Scope.new
      # parentComps =  []
     # subComps = []
      # targetComps = []
# 
    # ## D component
    # parentComps << "C" 
    # parentComps << "E" 
    # scope.addComponent("D", parentComps, subComps)
    # targetComps<< "D" 
    # scope.target=targetComps 
# 
    # ## C component
    # parentComp=[]
    # subComp=[]
    # parentComp << "B" 
    # subComp << "D" 
    # scope.addComponent("C", parentComp, subComp)

    
    ## E component
    # parentCom =[]
    # subCom =[]
    # parentCom << "B" 
    # subCom << "D" 
    # scope.addComponent("E", parentCom, subCom) 
# 
    # ## B component
    # parentCo =[]
    # subCo =[]
    # subCo <<"C" 
    # subCo << "E" 
    # scope.addComponent("B", parentCo , subCo )
# 
    # scope.isSpecifiedScope = true

     # tcc =  Dea::TxContext.new
    # tcc.currentTx = "657c-4791-4791-8fae-f1cda8d2dd53" 
    # tcc.hostComponent = "D" 
    # tcc.parentComponent="E" 
    # tcc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53" 
    # tcc.rootComponent="A"
    # tcc.rootTx="a358ab2d-cf1a-4e7e-857a-d89c2db40102" 
     # invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>B:xxxx-xxxx-xxxx-xxx>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53" 
    # tcc.invocationSequence=invocationSequence
    #assertEquals("xxxx-xxxx-xxxx-xxx", 
#     
    # puts
    # puts tcc.getProxyRootTxId(scope) 
    

##################test3 #######################3
scope =  Dea::Scope.new
      parentComps =  []
     subComps = []
      targetComps = []
parentComps<<"C" #
    parentComps<<"E" #
    scope.addComponent("D", parentComps, subComps)#

puts scope.parentComponents["D"]
    # C component
     parentComp =  []
     subComp = []
    parentComp<<"B" #
    subComp<<"D" #
    scope.addComponent("C", parentComp, subComp)#

    # E component
    parentCom=[]
    subCom =[]
    subCom<<"D"#
    scope.addComponent("E", parentCom , subCom )#

    # B component
    parentCo=[]
    subCo=[]
    subCo<<"C"#
    scope.addComponent("B", parentCo , subCo )#

    scope.isSpecifiedScope =true #

     tc =  Dea::TxContext.new #
    tc.currentTx="657c-4791-4791-8fae-f1cda8d2dd53" #
    tc.hostComponent="D" #
    tc.parentComponent="E" #
    tc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53" 
    tc.rootComponent="A" 
    tc.rootTx="a358ab2d-cf1a-4e7e-857a-d89c2db40102" 
      invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53"#
    tc.invocationSequence=invocationSequence 
    #assertEquals("d130a1f8-657c-4791-8fae-f1cda8d2dd53",
     puts   tc.getProxyRootTxId(scope) 

# /vagrant/dea_ng/lib/dea/conup/scope.rb:112: stack level too deep (SystemStackError)

##############################test4#########################
toString = "AuthComponent<ProcComponent#ProcComponent>AuthComponent#TARGET_COMP@AuthComponent#SCOPE_FLAG&true"# 
      scope = Dea::Scope.inverse(toString)# 
    
      tc =  Dea::TxContext.new# 
    tc.currentTx="657c-4791-4791-8fae-f1cda8d2dd53"# 
    tc.hostComponent="AuthComponent"# 
    tc.parentComponent="PortalComponent"# 
    tc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53"# 
    tc.rootComponent="PortalComponent"# 
    tc.rootTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53"# 
    tc.invocationSequence="PortalComponent:d130a1f8-657c-4791-8fae-f1cda8d2dd53"# 
    #assertEquals("657c-4791-4791-8fae-f1cda8d2dd53", 
    puts tc.getProxyRootTxId(scope)# 





