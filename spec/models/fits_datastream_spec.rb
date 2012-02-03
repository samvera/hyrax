require 'spec_helper'

describe FitsDatastream do
  before do
    @subject = FitsDatastream.new(nil, 'characterization')
    @subject.stubs(:pid=>'my_pid')
    @subject.stubs(:dsVersionID=>'characterization.3')
  end
  it "should read the fits meta data fields"
end
