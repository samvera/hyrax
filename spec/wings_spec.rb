# frozen_string_literal: true
require 'spec_helper'
require 'wings'

RSpec.describe Wings do
  it 'adds mixin to AF::Base' do
    expect(GenericWork.new).to respond_to :valkyrie_resource
  end
end
