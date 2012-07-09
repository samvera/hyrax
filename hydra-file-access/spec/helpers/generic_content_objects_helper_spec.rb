require 'spec_helper'

describe GenericContentObjectsHelper do
  before :all do
    @behavior = Hydra::GenericContentObjectsHelperBehavior.deprecation_behavior
    Hydra::GenericContentObjectsHelperBehavior.deprecation_behavior = :silence
  end

  after :all do
    Hydra::GenericContentObjectsHelperBehavior.deprecation_behavior = @behavior
  end
  
  it "should have a url for a pid" do
    helper.datastream_disseminator_url('hydra:123', 'sampleDs').should match /http:\/\/127.0.0.1:\d+\/fedora-test\/get\/hydra:123\/sampleDs/
  end

end
