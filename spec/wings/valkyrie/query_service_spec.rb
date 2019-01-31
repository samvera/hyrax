# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::QueryService do
  # it_behaves_like "a Valkyrie query provider"

  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:subject) { described_class.new(adapter: adapter) }

  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by)
    expect(subject).to respond_to(:resource_factory)
  end
end
