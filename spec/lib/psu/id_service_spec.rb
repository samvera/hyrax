require 'spec_helper'



describe PSU::IdService do
  
  describe "mint" do

   # saves original $stdout in variable
    # set $stdout as local instance of StringIO
    # yields to code execution
    # returns the local instance of StringIO
    # resets $stout to original value
    def capture_stdout
      out = StringIO.new
      $stdout = out
      yield
      return out.string
    ensure
      $stdout = STDOUT
    end
 
    
    it "should create a unique id" do
      @id = PSU::IdService.mint
      @id.should_not be_empty
      @id2 = PSU::IdService.mint
      @id2.should_not be_empty
      @id.should_not == @id2
    end
    
    it "shoud create many unique ids" do
     a = Array.new
     processes = []
          
     puts PSU::IdService.mint
     threads = (1..10).map do
       Thread.new do
          100.times do
              a <<  PSU::IdService.mint
          end
       end
     end
     threads.each(&:join)
        
     b = Hash.new
     a.each do |id|
       b[id] = id
     end
     puts "counts = #{b.keys.count} #{a.count}"
     a.count
     b.keys.count.should == a.count
    end


    it "multiple processes shoud create many unique ids" do
     a = Array.new
     processes = []

     rd, wr = IO.pipe
     2.times do
       pid = fork do 
        rd.close
        threads = (1..10).map do
          Thread.new do
              20.times do
                #Thread.pass
                wr.write PSU::IdService.mint
                wr.write " "
              end
          end
        end
        threads.each(&:join)        
        #sleep 0.001
        #wr.write PSU::IdService.mint
        #wr.write " "
        wr.close
        end
      end
      wr.close
      2.times do
        Process.wait
      end
      s = rd.read
      rd.close
      a = s.split(" ")

      b = Hash.new
       a.each do |id|
         if b.has_key?(id)
            logger.info "already in #{id}" 
         end
         b[id] = id
       end
       puts "counts = #{b.keys.count} #{a.count}"
       a.count
       b.keys.count.should == a.count
    end

  end

end

