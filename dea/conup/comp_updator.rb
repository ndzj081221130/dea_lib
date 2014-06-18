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
      @deletedAlready = false
    end
    
    def initUpdator(baseDir,port,instance,compIdentifier)
      @baseDir = baseDir
      @keyGet = compIdentifier +":" + port
      compObj = Dea::NodeManager.instance.getComponentObject(@keyGet)
      
      updateMgr = Dea::NodeManager.instance.getUpdateManager(@keyGet)
      #   here is update logic need to be changed for DEA
      updateCtx = updateMgr.updateCtx
      if updateCtx == nil
        updateCtx = Dea::DynamicUpdateContext.new
        updateCtx.isLoaded = true
        updateMgr.updateCtx = updateCtx
        
      end
      
        @already_pushed = false
      # actually , cf push new version here ? or earlier
    end
    
    def executeUpdate(compIdentifier,instance)     #  here execute, setConstructor, is this JavaImpl's job?  
      if instance
        
        nodeMgr = Dea::NodeManager.instance
        
        pushMonitor = nodeMgr.pushMonitor
        puts "#{@keyGet} try to enter updateMgr's push Monitor "
        pushMonitor.synchronize do
          
               puts "#{@keyGet} in updateMgr's push Monitor "
               cmd0 = "pwd"
            
                old_name = instance.application_name
              puts "#{@keyGet} #{old_name}"
              # tmp_name  = old_name + "_old"
              # cmd1 = "cf rename #{old_name} #{tmp_name}"
              # puts cmd1
              # tar_output1 = run_with_err_output cmd1
              # puts "exe rename result: #{tar_output1}"
               #---------------------#
               new_name = old_name+"_new"
               @already_pushed = instance.bootstrap.instance_registry.has_instances_for_application(new_name)
               
               puts "#{@keyGet} . already push = #{@already_pushed}"
              if @already_pushed
                puts "#{@keyGet}.already has #{new_name} instance, no need push ,just cf increate #{new_name}"
                
                command = "cf increase #{new_name}"
                
                puts "#{@keyGet}.#{command}"
                
                tar_output = run_with_err_output(command)# command, or system will new a sub process??
                puts "#{@keyGet}.compUpdator , exe cf increase result : #{tar_output}"
              else
                  
                command = "cd #{@baseDir} && cf push"
                puts "#{@keyGet}.#{command}"
                tar_output = run_with_err_output(command)# command, or system will new a sub process??
                puts "#{@keyGet}.compUpdator , exe push result : #{tar_output}"
              
              end
        end
        
        puts "#{@keyGet} out updateMgr's push Monitor "
        
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
      puts "#{@keyGet}.comp_updator : clean update" # 这里总是阻塞，why？
      
      node = Dea::NodeManager.instance 
      
      updateMgr = node.getUpdateManager(@keyGet)
      
      updateMgr.updateCtx = nil
      
      
      return true
    end
    
    def finalizeOld(compIdentifier,oldVersion,newVersion,instance)
      #we need to cf delete old? may be not this... we need to stop 
      if instance
        puts "#{@keyGet}.compUpdator.delete old version, or first ,stop old version"
        old_name = instance.application_name # old version name
        
        new_name = old_name+"_new"
        @already  = instance.bootstrap.instance_registry.has_instances_for_application(new_name)
        if @already == false #新版本还没部署好？
              # cmd1 = "cf stop #{old_name}  "
              # puts "#{@keyGet}. #{cmd1}"
              # tar_output1 = run_with_err_output cmd1
              # puts "#{@keyGet}.exe cf stop result: #{tar_output1}"
#               
              # nodeMgr = NodeManager.instance
              # nodeMgr.removeComponentsViaName(old_name)
               puts "#{@keyGet} #{old_name}_new hasn't been pushed, do nothing" 
               
        else
            # if @deletedAlready == false
                # cmd2 = "cf delete-force #{old_name}"
                # puts "#{@keyGet}. #{cmd2}"
                # tar_output1 = run_with_err_output cmd2
                # puts "#{@keyGet}.exe cf delete-force result: #{tar_output1}"
                # @deletedAlready = true
#                 
                nodeMgr = NodeManager.instance
                
                
                  puts " #{@keyGet} #{old_name } not removed , delete"
                  cmd2 = "cf delete-force #{old_name}"
                  puts "#{@keyGet}. #{cmd2}"
                  tar_output1 = run_with_err_output cmd2
                  puts "#{@keyGet}.exe cf delete-force result: #{tar_output1}"
                  nodeMgr.removeComponentsViaName(old_name)
                
                # 
#               
              # 
              # end
        end
      end
      return true
    end
    
    def initNewVersion(compName, newVersoin)
      return true
    end
  end
  
end