require 'spec_helper'

describe UnzipJob do
  before do
    @batch = Batch.create
    @generic_file = GenericFile.new(:batch=>@batch)
    @generic_file.add_file(File.open(fixture_path + '/icons.zip'), 'content', 'icons.zip')
    @generic_file.apply_depositor_metadata('mjg36')
    @generic_file.stub(:characterize_if_changed).and_yield #don't run characterization
    @generic_file.save
  end

  after do
    @batch.delete
    @generic_file.delete
  end

  it "should create GenericFiles for each file in the zipfile" do
    one = GenericFile.new
    #one.should_receive(:characterize_if_changed)
    two = GenericFile.new
    #two.should_receive(:characterize_if_changed)
    three = GenericFile.new
    #three.should_receive(:characterize_if_changed)
    GenericFile.should_receive(:new).exactly(3).times.and_return(one, two, three)
    UnzipJob.new(@generic_file.pid).run

    one.content.size.should == 13024 #bread
    one.content.label.should == 'spec/fixtures/bread-icon.png'
    one.content.mimeType.should == 'image/png'
    one.batch.should == @batch

    two.content.size.should == 12995 #coffee
    two.content.label.should == 'spec/fixtures/coffeecup-red-icon.png'
    two.content.mimeType.should == 'image/png'
    two.batch.should == @batch

    three.content.size.should == 58097 #hamburger
    three.content.label.should == 'spec/fixtures/hamburger-icon.png'
    three.content.mimeType.should == 'image/png'
    three.batch.should == @batch

    one.delete
    two.delete
    three.delete
  end
end
