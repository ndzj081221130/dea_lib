# UTF-8

require "../conup/tx_registry"

tr = Dea::TransactionRegistry.new

txCtx = Dea::TxContext.new
invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53"

txCtx.invocationSequence = invocationSequence

#puts invocationSequence

str= "AuthComponent<ProcComponent#"+
"AuthComponent<PortalComponent#ProcComponent<PortalComponent#ProcComponent>AuthComponents#"+
"PortalComponent>AuthComponent#PortalComponent>ProcComponent#TARGET_COMP@AuthComponent#SCOPE_FLAG&true"

scope2 = Dea::Scope.inverse(str)

tc = Dea::TxContext.new

tc.currentTx="657c-4791-4791-8fae-f1cda8d2dd53"
tc.hostComponent="AuthComponent"
tc.parentComponent="ProcComponent"
tc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53"
tc.rootComponent="PortalComponent"
tc.rootTx="a358ab2d-cf1a-4e7e-857a-d89c2db40102"

tr.addTransactionContext("abc???",tc)

scope =  Dea::Scope.new
      parentComps =  []
     subComps = []
      targetComps = []
# 
    # ## D component
    parentComps << "C" 
    parentComps << "E" 
    scope.addComponent("D", parentComps, subComps)
    targetComps<< "D" 
    scope.target=targetComps 
# 
    # ## C component
    parentComp=[]
    subComp=[]
    parentComp << "B" 
    subComp << "D" 
    scope.addComponent("C", parentComp, subComp)

    
    ## E component
    parentCom =[]
    subCom =[]
    parentCom << "B" 
    subCom << "D" 
    scope.addComponent("E", parentCom, subCom) 
# 
    # ## B component
    parentCo =[]
    subCo =[]
    subCo <<"C" 
    subCo << "E" 
    scope.addComponent("B", parentCo , subCo )
# 
    scope.isSpecifiedScope = true

     tcc =  Dea::TxContext.new
    tcc.currentTx = "657c-4791-4791-8fae-f1cda8d2dd53" 
    tcc.hostComponent = "D" 
    tcc.parentComponent="E" 
    tcc.parentTx="d130a1f8-657c-4791-8fae-f1cda8d2dd53" 
    tcc.rootComponent="A"
    tcc.rootTx="a358ab2d-cf1a-4e7e-857a-d89c2db40102" 
     invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>B:xxxx-xxxx-xxxx-xxx>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53" 
    tcc.invocationSequence=invocationSequence

    tr.addTransactionContext("def???",tcc)
    # tr.removeTransactionContext("abc???")
    puts tr.contains("abc???") == nil
     puts tr.getTransactionContext("abc???") 
    tr.updateTransactionContext("abc???" , tcc)
    puts tr.getTransactionContext("abc???") #== nil
    
    keys = tr.getAllTxIds
    
    keys.each{|k| puts k}
    
    contxts = tr.getTransactionContexts
    
    contxts.each{|t| puts t}
