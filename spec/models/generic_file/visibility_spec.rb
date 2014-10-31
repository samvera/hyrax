require 'spec_helper'

describe Sufia::GenericFile, :type => :model do
  module VisibilityOverride
    extend ActiveSupport::Concern
    include Sufia::GenericFile::Permissions
    def visibility; super; end
    def visibility=(value); super(value); end
  end
  class MockParent < ActiveFedora::Base
    include VisibilityOverride
  end

  it 'allows for overrides of visibility' do
    expect{
      MockParent.new(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
    }.to_not raise_error
  end
end
