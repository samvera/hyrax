# frozen_string_literal: true
require 'spec_helper'
require 'wings/metadata_adapter'

RSpec.describe Wings::MetadataAdapter do
  let(:subject) { described_class.new }

  it 'responds to expected methods' do
    expect(subject).to respond_to(:query_service)
    expect(subject).to respond_to(:resource_factory)
  end

  describe '.query_service' do

  end

  describe '.resource_factory' do

  end
end
