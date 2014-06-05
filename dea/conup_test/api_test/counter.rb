require 'monitor'
class Counter < Monitor
  attr_reader :count
  def initialize
    @count = 0
    super
  end
  
  def click
    synchronize do 
      
      @count += 1
      
    end
    
  end
end

# c = Counter.new
# 
# t1 = Thread.new{100_100.times{c.click}}
# t2 = Thread.new{100_100.times{c.click}}
# 
# 
# t1.join;t2.join
# 
# puts c.count

flag =false

str = "res = " + flag.to_s

puts str
