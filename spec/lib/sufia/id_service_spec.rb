require 'spec_helper'

describe Sufia::IdService do
  describe "mint" do
    before(:all) do
      @id = Sufia::IdService.mint
    end
    it "should create a unique id" do
      @id.should_not be_empty
    end
    it "should not mint the same id twice in a row" do
      other_id = Sufia::IdService.mint
      other_id.should_not == @id
    end  
    it "should create many unique ids" do
      a = []
      threads = (1..10).map do
        Thread.new do
          100.times do
            a <<  Sufia::IdService.mint
          end
        end
      end
      threads.each(&:join)     
      a.uniq.count.should == a.count
    end
    it "should create many unique ids when hit by multiple processes " do
      rd, wr = IO.pipe
      2.times do
        pid = fork do 
          rd.close
          threads = (1..10).map do
            Thread.new do
              20.times do
                wr.write Sufia::IdService.mint
                wr.write " "
              end
            end
          end
          threads.each(&:join)        
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
      a.uniq.count.should == a.count
    end
  end
end
