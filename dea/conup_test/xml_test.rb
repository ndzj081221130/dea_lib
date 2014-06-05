# UTF-8

require_relative "../conup/xml_util"
require "set"

set1 = Set.new

set1 << "a"
set2 << "b"
xmlUtil = Dea::XMLUtil.new

# parents = xmlUtil.getParents("AuthComponent")
# 
# parents.each{|p| puts p}
# # 
# puts "Protal children:"
# children = xmlUtil.getChildren("PortalComponent")
# children.each{|c| puts c}
# 
# puts 
# 
# procP = xmlUtil.getParents("ProcComponent")
# procP.each{|p| puts p}
# puts "Proc children :"
# procC = xmlUtil.getChildren("ProcComponent")
# procC.each{|p| puts p}




#puts xmlUtil.getAllComponents

#puts "-------------"
#puts xmlUtil.getAllComponentsComm

