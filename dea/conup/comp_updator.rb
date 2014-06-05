# UTF-8
# 
require_relative "./update_mgr" 
require_relative "./node_mgr"
module Dea
  class CompUpdator
    IMPL_TYPE ="JAVA_POJO"
    attr_accessor :isUpdated
    attr_accessor :baseDir
    
    def initiate
      isUpdated=false
    end
    
    def initUpdator(baseDir,classPath,contributionURI,instance,compIdentifier)
      @baseDir = baseDir
      compObj = Dea::NodeManager.instance.getComponentObject(compIdentifier)
      
      updateMgr = Dea::NodeManager.instance.getUpdateManager(compIdentifier)
      #   here is update logic need to be changed for DEA
      updateCtx = updateMgr.updateCtx
      if updateCtx == nil
        updateCtx = Dea::DynamicUpdateContext.new
        updateCtx.isLoaded = true
        updateMgr.updateCtx = updateCtx
        
      end
      
        
      # actually , cf push new version here ? or earlier
    end
    
    def executeUpdate(compIdentifier,instance)     #  here execute, setConstructor, is this JavaImpl's job?  
      if instance
        cmd0 = "pwd"
      
        # old_name = instance.application_name
        # puts old_name
        # tmp_name  = old_name + "_old"
        # cmd1 = "cf rename #{old_name} #{tmp_name}"
        # puts cmd1
        # tar_output1 = run_with_err_output cmd1
        # puts "exe rename result: #{tar_output1}"
         #---------------------#
        command = "cd #{@baseDir} && cf push"
        puts command
        tar_output = run_with_err_output(command)# command, or system will new a sub process??
         puts "#{compIdentifier}.compUpdator , exe push result : #{tar_output}"
        
        isUpdated= true
        return true
      else
        isUpdated = false
        return false
      end
      
    end
    
     # run a shell command and pipe stderr to stdout
    # @param [String] command to be run
    # @return [String] output of stdout and stderr
    def run_with_err_output(command)
      %x{ #{command} 2>&1 }
    end
    
    def cleanUpdate(compIdentifier)
      puts "comp_updator : clean update" # 这里总是阻塞，why？
      node = Dea::NodeManager.instance 
      
      updateMgr = node.getUpdateManager(compIdentifier)
      
      updateMgr.updateCtx = nil
      
      
      return true
    end
    
    def finalizeOld(compIdentifier,oldVersion,newVersion,instance)
      #we need to cf delete old? may be not this... we need to stop 
      if instance
        puts "#{compIdentifier}.compUpdator.delete old version, or first ,stop old version"
        old_name = instance.application_name # old version name
        # puts old_name
        # tmp_name  = old_name + "_old"
        cmd1 = "cf stop #{old_name}  "
        puts cmd1
        tar_output1 = run_with_err_output cmd1
        puts "exe cf stop result: #{tar_output1}"
        
      end
      return true
    end
    
    def initNewVersion(compName, newVersoin)
      return true
    end
  end
  
end