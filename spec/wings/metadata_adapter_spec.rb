# frozen_string_literal: true
require 'spec_helper'
require 'wings/metadata_adapter'

RSpec.describe Wings::MetadataAdapter do
  let(:subject) { described_class.new }
  it_behaves_like "a Valkyrie::MetadataAdapter"

  it 'responds to expected methods' do
    expect(adapter).to respond_to(:resource_factory)
  end
end
