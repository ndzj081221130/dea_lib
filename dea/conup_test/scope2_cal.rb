#UTF-8

require "../conup/scope"
require "../conup/xml_util"

def calcScope(id)
      scope = Dea::Scope.new
      xmlUtil = Dea::XMLUtil.new
      compIdentifier = id
      
      scopeComps = Set.new
      
      queue = Array.new # Queue<String>
      queue << compIdentifier
      while queue.empty? == false
        compInQueue = queue.shift
        parents = xmlUtil.getParents(compInQueue)
        parents.each{|parent|
          queue << parent
          scopeComps << parent
          }
        
      end
      
      scopeComps << compIdentifier
      
      scopeComps.each{|compName|
          subs = xmlUtil.getChildren(compName)
          
          subs.each{|sub| 
            if !scopeComps.include? sub # scopeComps is set
              # scopeComps << sub
              subs.delete sub
            end
            }
          scope.addComponent(compName,xmlUtil.getParents(compName),subs)
        }
      targetComps = Set.new  
      targetComps << id
      scope.target = targetComps
      
      return scope  
    end
     

puts calcScope("HelloworldComponent")
