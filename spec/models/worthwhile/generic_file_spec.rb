require 'spec_helper'

describe Worthwhile::GenericFile do
  it "should have depositor" do
    subject.depositor = 'tess@example.com'
  end
end
