require "../conup/tx_dep"

futureComps = Array.new
futureComps << "ProcComponent"
futureComps << "PortalComponent"

future = Array.new(futureComps)

future.each{|f|
  puts "f:#{f}"
  }
pastComps = Array.new
pastComps << "AuthComponent"
pastComps << "ProcComponent"

tx_dep = Dea::TxDep.new(futureComps,pastComps)

puts tx_dep
puts tx_dep.pastComponents.size
puts tx_dep.futureComponents.size

puts tx_dep.futureComponents.include? "DBComponent"

tx_dep.futureComponents << "DBComponent"
puts tx_dep.futureComponents.include? "DBComponent"

puts tx_dep

tx_dep.futureComponents.clear
puts tx_dep

#tx_dep.pastComponents.delete "ProcComponent"


tx_dep.pastComponents.delete_if { |e| e > "AuthComponent"  }

puts tx_dep

