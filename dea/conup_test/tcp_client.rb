    # p069dtclient.rb  
    require 'socket'  
    require 'json'
    streamSock = TCPSocket.new( "192.168.12.34", 6666 ) 
    
    msg = {}

    msg["InstanceId"] = "2203a1b2a76d5812d84ba6a67ecb2d7922ae051c75518d5804ae3a2a00f0be67"#Cons::Hello_Instance_Id
    ref = msg.to_json  
 
    streamSock.write( ref )  
    str = streamSock.recv( 100 )  
    print str  
    streamSock.close  