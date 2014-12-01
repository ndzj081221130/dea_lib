#UTF-8

    def run_with_err_output(command)
      %x{ #{command} 2>&1 }
    end
    
    today = Time.new
puts today

    baseDir = "/vagrant/test/helloworld-call"
    command = "cd #{baseDir} && cf push"
    puts " #{command}"
    tar_output = run_with_err_output(command)# command, or system will new a sub process??
    puts "  exe push result : #{tar_output}"
    
today = Time.new
puts today