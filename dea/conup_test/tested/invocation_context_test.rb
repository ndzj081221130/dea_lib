# UTF-8

require "../conup/invocation_context"

invocationSequence = "A:a358ab2d-cf1a-4e7e-857a-d89c2db40102>E:d130a1f8-657c-4791-8fae-f1cda8d2dd53"

rootTx = "xxx-dddx-sssd-ddd"
rootComp="PortalComponent"

parentTx="aaa-bvv-ddd-ddd"
parentComp="PortalComponent"

subTx = "sss-uuuu-bbb-tttx"
subComp ="AuthComponent"

ic1 = Dea::InvocationContext.new(rootTx,rootComp,parentTx,parentComp,subTx,subComp,invocationSequence)
puts ic1
str = ic1.to_s
puts str.include? "a"
ic2 = Dea::InvocationContext.getInvocationCtx(str)

puts "root:"
puts ic2.rootTx

puts ic2.rootComp
puts "parent:"
puts ic2.parentTx

puts ic2.parentComp
puts "sub:"
puts ic2.subTx

puts ic2.subComp

puts ic2.invokeSequence