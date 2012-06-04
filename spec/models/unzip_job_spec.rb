require 'spec_helper'

describe UnzipJob do
  before(:all) do
    @batch = Batch.create
    GenericFile.any_instance.expects(:characterize_if_changed).at_least_once.yields
    @generic_file = GenericFile.new(:batch=>@batch)
    @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/icons.zip'), :dsid=>'content')
    @generic_file.save
  end

  after(:all) do
    @batch.delete
    @generic_file.delete
  end

  it "should create GenericFiles for each file in the zipfile" do
    one = GenericFile.new
    two = GenericFile.new
    three = GenericFile.new
    GenericFile.expects(:new).times(3).returns(one, two, three)
    UnzipJob.new(@generic_file.pid).perform

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
