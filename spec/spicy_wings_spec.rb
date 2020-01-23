require 'spec_helper'
require 'spicy_wings'

RSpec.describe SpicyWings do
  it 'adds mixin to AF::Base' do
    expect(GenericWork.new).to respond_to :valkyrie_resource
  end
end
