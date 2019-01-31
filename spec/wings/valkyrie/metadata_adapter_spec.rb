# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::MetadataAdapter do
  let(:adapter) { described_class.new }
  # it_behaves_like "a Valkyrie::MetadataAdapter"

  it 'responds to expected methods' do
    expect(adapter).to respond_to(:resource_factory)
  end
end
