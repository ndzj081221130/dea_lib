# coding: UTF-8
#conup-core
require "steno"
require "steno/core_ext"
require_relative "./dep"
require "set"
module Dea
  class DependenceRegistry
    
    attr_accessor :dependences # set {concurrent skiplist set<Dependence>}
    
    def initialize
      @dependences = Set.new
    end
    
    def addDependence( depe)
      @dependences << depe
      
      
      puts "DepRegistry : after add , dependences begin" 
        @dependences.each{|dep|
          puts dep
        }
        puts "dependences end \n"
    end

    def removeDependenceViaDep(depe)
       f = @dependences.delete(depe)
      puts "DepRegistry : after removeViaDep #{dep} , dependences begin" 
        @dependences.each{|dep|
          puts dep
        }
        puts "dependences end \n"
      return f 
    end
    
    def removeDependence(type,rootTx,srcComp,targetComp) # srcComp is string
       
        f = @dependences.delete_if{|dep| dep.type == type && dep.rootTx == rootTx && 
           dep.srcCompObjIdentifier == srcComp  && dep.targetCompObjIdentifier == targetComp }#false
        puts "DepRegistry : after remove #{srcComp} --> #{targetComp} rootTx = #{rootTx} ,type = #{type},\n dependences begin" 
        @dependences.each{|dep|
          puts dep
        }
        puts "dependences end \n"
        return f
        
         
    end
    
    
    def getDependencesViaType(type)
      arr = Set.new
      
      @dependences.each{|dep|
        if dep.type == type
          arr << dep
        end
        }
        
        
        return arr
    end
    
    def getDependencesViaRootTransaction(rootTX)
      arr = Set.new
      
      @dependences.each{|dep|
        
        if dep.rootTx == rootTX
          arr << dep
        end
        }
        
        return arr
    end
    
    def getDependencesViaTargetComponent(target)
      arr = Set.new
      @dependences.each{|dep|
        if dep.targetCompObjIdentifier == target
          arr << dep
        end
        }
        
        return arr
    end
    
    def getDependencesViaSourceService(srcService)
    
      arr = Set.new
      @dependences.each{|dep|
        if dep.sourceService == srcService
          arr << dep
        end
        }
      return arr
    end
    
    def getDependencesViaTargetService(targetService)
      arr = Set.new
      @dependences.each{|dep|
        
        if dep.targetService == targetService
          arr << dep
        end
        }
        
      return arr
    end
    
    
    def contain(dep)
      return @dependences.include? dep
    end
    
    def size
      return @dependences.size
    end
    
    
    def to_s
      str = "---dep_registry_begin----\n"
      @dependences.each{|dep|
        
        str+= "dep = #{dep}\n"
        }
        
     str += "\n---dep_registry_end----\n"
     str   
    end
    
    
    
  end
end
