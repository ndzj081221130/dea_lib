# coding: UTF-8
#conup-spi/datamodel
require "steno"
require "steno/core_ext"
require "set"

module Dea
  class Scope
    
    PARENT_SEPERATOR = "<"
    SUB_SEPERATOR = ">"
    
    SCOPE_ENTRY_SEPERATOR = "#"
    TARGET_IDENTIFIER = "TARGET_COMP"
    TARGET_SEPERATOR = "@"
    SCOPE_FLAG_IDENTIFIER = "SCOPE_FLAG"
    SCOPE_FLAG_SEPERATOR = "&"
    
    attr_accessor :parentComponents # hash<String , Set<String>}
    attr_accessor :subComponents # hash<String , Set<String>}
   
    attr_accessor :components # Set<String>
    attr_accessor :target # Set<String>
     
    attr_accessor :isSpecifiedScope
    
    def initialize
      @components = Set.new#{}
      @target = Set.new# {}
      
      @parentComponents = {} # hash{String = component ,array}
      @subComponents = {}
      @isSepcifiedScope=false
    end
   
    def addComponent(compName,parent,sub) # parent is a  set , sub is a set , compName is str
      @components << compName
      
      if ! @parentComponents.has_key?(compName)#!@parentComponents.has_value?(parent)
        @parentComponents[compName] = Set.new
      end
      
      parent.each{|p|
        
          @parentComponents[compName] << p
        
        }
      
      if ! @subComponents.has_key?(compName)
        @subComponents[compName] = Set.new
      end
      
      sub.each{|s|
         
          @subComponents[compName] << s
         
        }
    end
     
     def setComponent(compName, parent,sub)
       if !@components.include?(compName) 
           @components << compName
       end
       @parentComponents[compName] = parent
       @subComponents[compName] = sub
     end
     
     def to_s
       str=""
       
       @parentComponents.each{|key,value|
         value.each do |parent|
           str += key + PARENT_SEPERATOR + parent + SCOPE_ENTRY_SEPERATOR
         end
       }
       
       @subComponents.each{  |key,value|
         value.each do |sub|
           str += key + SUB_SEPERATOR + sub + SCOPE_ENTRY_SEPERATOR
         end
       } 
         
       target.each{ |tar|
         
         str += TARGET_IDENTIFIER + TARGET_SEPERATOR + tar + SCOPE_ENTRY_SEPERATOR
       }  
       
       str += SCOPE_FLAG_IDENTIFIER + SCOPE_FLAG_SEPERATOR #+
       if @isSpecifiedScope 
       str += "true"
       else
         str += "false"
       end
       return str
     end
     
     def isTarget(compName)
       return target.include? compName
     end
     
     def getRootComp(curComp)
       rootComps = Set.new
       calcRootComps(curComp,rootComps)
       if !rootComps.include?(curComp)
          rootComps << curComp
       end
       return rootComps
     end
     
     def calcRootComps(curComp , rootComps)
       @parentComponents.each{|p| puts "parent:#{p}"}
       puts curComp
       if @parentComponents[curComp] == nil || @parentComponents[curComp].size == 0
         puts "nil or 0"
         if !rootComps.include?(curComp)
            rootComps << curComp
         end
         return rootComps
       end
       
       arr = @parentComponents[curComp]
       puts "arr:#{arr.size}"
       arr.each{
         |parent| calcRootComps(parent,rootComps)
         
       }
       return rootComps
     end
     
     def Scope.inverse(scopeString)
       if scopeString == nil
         return nil
       end
       scope = Scope.new
       
       split = scopeString.split(/#/) # is #
       puts "split = #{split.size}"
       split.each{|entry|
         if entry.include?("<") 
           part = entry.split(/</) # is < 
           curComp = part[0]
           
           parentComps = Set.new
           parentComps << part[1]
           scope.addComponent(curComp,parentComps,Set.new)
          # puts "scope : #{scope}"
         elsif entry.include?(">")
           sub_part = entry.split(/>/) # is >
           curComp = sub_part[0]
           subComps = Set.new
           subComps << sub_part[1]
           scope.addComponent(curComp , Set.new, subComps)
         elsif entry.include?("@")
           
           targetComp = entry.split(/@/)[1]
           
           scope.target << targetComp
         elsif entry.include?("&")
           if entry.split(/&/)[1] == "true"
           scope.isSpecifiedScope= true
           else
             
             scope.isSpecifiedScope= false
           end
         else
            return nil    
         end
         
         
       }
       
       if scope.target.size ==0
         return nil
       end
       return scope
     end
     
     
     def contains(compName)
       return components.include?(compName)
     end
     
     
  end
end
