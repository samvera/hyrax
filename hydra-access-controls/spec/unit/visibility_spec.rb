require 'spec_helper'

describe Hydra::AccessControls::Visibility do
  module VisibilityOverride
    extend ActiveSupport::Concern
    include Hydra::AccessControls::Permissions
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
