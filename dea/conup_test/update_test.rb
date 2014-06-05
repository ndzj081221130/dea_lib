        
        def run_with_err_output(command)
      %x{ #{command} 2>&1 }
    end
    
        
        old_name = "tuscany"#instance.application_name
        puts old_name
        tmp_name  = old_name + "_old"
        cmd1 = "cf rename #{old_name} #{tmp_name}"
        puts cmd1
        tar_output1 = run_with_err_output cmd1
        
        puts tar_output1
        # instance.application_id
        # data[:application_version] = instance.application_version
        # data[:application_name]    = instance.application_name
        command = "cd /vagrant/test/helloworld-jsonrpc2 && cf push"
        puts command
        tar_output = run_with_err_output command
        puts tar_output

