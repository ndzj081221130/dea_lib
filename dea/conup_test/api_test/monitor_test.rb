require 'monitor'
require 'mathn'

numbers = []
numbers.extend(MonitorMixin)

numbers_add = numbers.new_cond

Thread.new do 
  
  loop do
    numbers.synchronize do
      puts "wait?"
      numbers_add.wait#_while(numbers.empty?)
      # puts "contented"
      puts "reported:#{numbers.shift}"
    end
  end
  
end


generator = Thread.new do 
  
  p = 1#Prime.instance
  5.times do 
    
    numbers.synchronize do
      p += 1
      puts "p= #{p}"
      numbers << p 
      # puts numbers
      numbers_add.signal
      puts "after signal"
    end
    
  end
  
end

generator.join