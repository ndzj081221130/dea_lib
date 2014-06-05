require 'monitor'
class ThreadTest
  include MonitorMixin
  
  # resource,同步资源
  attr_accessor :sources,:cond
  
  def initialize
    # 注意,如果自己写initialize方法，super不能省略
    super
    self.cond = new_cond
    self.sources = []
  end
  
  # 生产者
  # 有2个线程不停的向resource中生产资源
  def start_producer_thread
    ts = []
    2.times do |i| 
      ts << Thread.new do
        Thread.current[:name] = "producer thread #{i + 1}"
        loop do 
          synchronize do
            p = sources.size == 0 ? 1 : sources.last + 1
            self.sources << p
            puts "[#{Thread.current[:name]}] create one product : #{p.to_s.rjust(4)}"
            cond.signal
            sleep 0.2
          end
        end
      end
    end
    ts
  end
  
  # 消费者
  # 有3个线程不停的从资源（resource）中取得
  def start_consumer_thread
    ts = []
    3.times do |i|
      ts << Thread.new do
        Thread.current[:name] = "consumer thread #{i + 1}"
        loop do
          synchronize do
            p = sources.shift
            puts "[* #{Thread.current[:name]}] consume one product : #{p.to_s.rjust(8)}"
            cond.signal
          end
        end
      end
    end
    ts
  end
  
  def do_it
    ts = []
    # 生产者线程开始
    ts << start_producer_thread
    sleep 1
    # 1秒钟后，消费者线程开始
    ts << start_consumer_thread
    # 挂起主线产程，直到生产者与消费者线程结束
    ts.flatten.each(&:join)
  end
end
ThreadTest.new.do_it