# UTF-8
# 
require_relative "./update_mgr" 
require_relative "./node_mgr"
module Dea
  class CompUpdator
    IMPL_TYPE ="JAVA_POJO"
    attr_accessor :isUpdated
    attr_accessor :baseDir
    attr_accessor :logger2
    def initialize #initialize
      isUpdated=false
      @deletedAlready = false
       
      setup_logging
    
      
    end
    
    def initUpdator(baseDir,port,compositeUri,compIdentifier)
      @baseDir = baseDir
      @keyGet = compIdentifier +":" + port
      compObj = Dea::NodeManager.instance.getComponentObject(@keyGet)
      @targetUri = compositeUri
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
              logger2.debug "#{@keyGet} try to enter updateMgr's push Monitor "
              pushMonitor.synchronize do
            
              logger2.debug "#{@keyGet} in updateMgr's push Monitor "
              cmd0 = "pwd"
          
              old_name = instance.application_name
              logger2.debug "#{@keyGet} #{old_name}"
               
               #----------this is actually pushed another app but bind to the same url -----------#
               new_name = old_name+"_new"
               @already_pushed = instance.bootstrap.instance_registry.has_instances_for_application(new_name)
               
               logger2.debug "#{@keyGet} . already push = #{@already_pushed}"
            if @already_pushed
                puts "#{@keyGet}.already has #{new_name} instance, no need push ,just cf increate #{new_name}"
                
                command = "cf increase #{new_name}"
                
                logger2.debug "#{@keyGet}.#{command}"
                
                tar_output = run_with_err_output(command)# command, or system will new a sub process??
                logger2.debug "#{@keyGet}.compUpdator , exe cf increase result : #{tar_output}"
                
                today = Time.new

                logger2.debug "increase instance , today =  #{today}"
                
                logger.info("increase instance today = #{today}")
            else
                  
                command = "cd #{@baseDir} && cf push"
                logger2.debug "#{@keyGet}.#{command}"
                tar_output = run_with_err_output(command)# command, or system will new a sub process??
                logger2.debug "#{@keyGet}.compUpdator , exe push result : #{tar_output}"
                today_push = Time.new
                logger2.debug "push instance , today = #{today_push}"
                
                logger.info("push instance today = #{today_push}")
            end
        end
        
        logger2.debug "#{@keyGet} out updateMgr's push Monitor? "
        
        
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
              
           puts "#{@keyGet} #{old_name}_new hasn't been pushed, do nothing" 
               
        else
          
            nodeMgr = NodeManager.instance
          
            puts " #{@keyGet} #{old_name } not removed , delete map first"
            
           
            cmd3 = "cf unmap #{@targetUri} #{old_name}"
            puts "#{@keyGet}.execute #{cmd3}"
            #target_output3 =
             run_with_err_output cmd3
           # puts "#{@keyGet} .exe cf unmap #{@targetUri} #{old_name}, result : #{target_out3}"
            nodeMgr.removeComponentsViaName(old_name)
              
                 
        end
      end
      return true
    end
    
    def initNewVersion(compName, newVersoin)
      return true
    end
    
    def setup_logging
      
      @log_counter = Steno::Sink::Counter.new
       
       
      logging = {}#config["logging"]

      options = {
        :sinks => [],
      }

      if logging["level"]
        options[:default_log_level] = logging["level"].to_sym
      end
      logging["file"] = "/vagrant/logs/updator.log"
      if logging["file"]
        options[:sinks] << Steno::Sink::IO.for_file(logging["file"])
      end

      if logging["syslog"]
        Steno::Sink::Syslog.instance.open(logging["syslog"])
        options[:sinks] << Steno::Sink::Syslog.instance
      end

      if options[:sinks].empty?
        options[:sinks] << Steno::Sink::IO.new(STDOUT)
      end

      options[:sinks] << @log_counter

      Steno.init(Steno::Config.new(options))
      
       
    end
    
    
    private

    def logger2
      @logger2 ||= Logger.new("/vagrant/logs/comp_updator.log")
    end
    
    def logger2=(logger_)
      @logger2 = logger_
    end 
    
    def logger
      @logger ||= self.class.logger
    end
    
    
    
  end
  
end