# frozen_string_literal: true
require 'spec_helper'
require 'wings/persister'

RSpec.describe Wings::Persister do
  let(:adapter) { Wings::MetadataAdapter.new }
  let(:subject) { described_class.new(adapter: adapter) }

  it 'responds to expected methods' do
    expect(subject).to respond_to(:save)
    expect(subject).to respond_to(:delete)
    expect(subject).to delegate_method(:resource_factory).to(:adapter)
  end

  describe '.save' do

  end

  describe '.delete' do

  end
end
