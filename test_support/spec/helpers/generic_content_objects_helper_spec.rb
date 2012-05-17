require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GenericContentObjectsHelper do
  it "should have a url for a pid" do
    helper.datastream_disseminator_url('hydra:123', 'sampleDs').should match /http:\/\/127.0.0.1:898\d\/fedora-test\/get\/hydra:123\/sampleDs/
  end

end
