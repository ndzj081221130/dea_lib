# UTF-8
require_relative "./update_context_payload"
module Dea
  class UpdateContextPayloadCreator
    def UpdateContextPayloadCreator.createPayload(*args)
      result = ""
      puts "args = #{args} , args.size = #{args.size}"
      if args.size == 1
        puts "update_context_payload_creator : #{args[0]}"
        puts "size = #{args.size}"
        result = Dea::UpdateContextPayload::OPERATION_TYPE + ":" + args[0]
        return result
      elsif args.size == 2
        
        result = Dea::UpdateContextPayload::OPERATION_TYPE + ":" + args[0] + "," + 
                 Dea::UpdateContextPayload::COMP_IDENTIFIER + ":" + args[1]
        return result   
      elsif args.size == 3
        result = createPayload(args[0],args[1])
        if args[2] != nil
          result += "," + Dea::UpdateContextPayload::SCOPE + ":" + args[2].to_s
        end        
        
        return result
      elsif args.size == 4
         result = Dea::UpdateContextPayload::OPERATION_TYPE + ":" + args[0] + "," + 
                  Dea::UpdateContextPayload::COMP_IDENTIFIER + ":" + args[1] + "," + 
                  Dea::UpdateContextPayload::BASE_DIR + ":" + args[2] + "," +            
                  Dea::UpdateContextPayload::COMPOSITE_URI + ":" + args[3]
         return result        
      elsif args.size == 5 
        result = createPayload(args[0],args[1],args[2],args[3])
        if args[4] != nil
          result += "," + Dea::UpdateContextPayload::SCOPE + ":" + args[4].to_s
          
        end
        return result
      else
        return "illegal args size"      
      end
      
      
    end
  end
end