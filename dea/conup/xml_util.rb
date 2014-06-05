# coding: UTF-8
#conup-spi
require "steno"
require "steno/core_ext"
require "rexml/document"
include REXML

module Dea
  class XMLUtil
    attr_accessor :root
    attr_accessor :xmldoc
    
    attr_accessor :comm
    
    def initialize
      xmlFile = File.new("/vagrant/dea_ng/lib/dea/conup/Conup.xml")
      @xmldoc = Document.new(xmlFile)
      @root = xmldoc.root
      @comm = {}
      # puts @root
    end
    
    def getAlgorithmConf
      algConf ="VersionConsistency"
      @xmldoc.elements.each("configuration/algorithms"){|e|
        
        if e.attributes["enable"] == "yes"
          algConf = e.text
          break
        end
        
        }
        
        return algConf
    end
    
    def getFreenessStrategy
      strategyConf = "CONCURRENT"
      
      @xmldoc.elements.each("configuration/freenessStrategies"){|e|
        
        if e.attributes["enable"] == "yes"
          strategyConf = e.text
          break
        end
        }
        
        return strategyConf
    end
    
    def getParents(compIdentifier)
      
      parentComps = Set.new
      
      @xmldoc.elements.each("conup/staticDeps/component"){|e|
        # puts e
        compName = e.attributes["name"]
       
        if compName == compIdentifier
           # puts "cName = #{compName}"
          e.elements.each("parent"){|child|
            # if child["parent"] != nil
               parentComps << child.text
            # end
            # puts child
            }
        end
        }
        
        return parentComps
    end
    
    def getChildren(compIdentifier)
      
      childrenComps = Set.new
      
      @xmldoc.elements.each("conup/staticDeps/component"){|e|
        compName = e.attributes["name"]
        if compName == compIdentifier
           
            e.elements.each("child"){|c|
              
              childrenComps <<  c.text
              }
        end
      }
      
      return childrenComps
    end
    
    
    def getAllComponents
      allComps = Set.new
      
      @xmldoc.elements.each("conup/staticDeps/component"){|e|
        
        compName = e.attributes["name"]
        # puts compName
          allComps << compName
        }
      
      return allComps
    end
    
    def getAllComponentsComm
      allCompsComm = {}
      
      @xmldoc.elements.each("conup/staticDeps/component"){|e|
        
        compName = e.attributes["name"]
        # puts compName
        comm = e.attributes["collect_port"]
        # puts comm
        if comm != nil
          allCompsComm[compName] = comm 
        end
        }
      
      return allCompsComm
    end
    
    
    
    
  end
end