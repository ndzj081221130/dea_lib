# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "AuthComponent"
port = "8000"
baseDir ="/vagrant/test/helloworld-auth2"
classFilePath=""
contributionUri=""
compositeUri=""
# 
# rcs.update
protocol = "CONSISTENCY"
# rcs.ondemand(ip,port,targetIdentifier,protocol,nil)

    def run_with_err_output(command)
      %x{ #{command} 2>&1 }
    end
    
        command = "cd #{baseDir} && cf push"
        puts command
          #tar_output = run_with_err_output(command)# command, or system will new a process??
          #puts "#{targetIdentifier}.compUpdator , exe push result : #{tar_output}"
    
  rcs.update(ip,port,targetIdentifier,protocol,baseDir,classFilePath,contributionUri,compositeUri,nil)

