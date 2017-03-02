require 'spec_helper'

RSpec.describe Sufia::Workflow::CompleteNotification do
  let(:entity) { double(:sipity_entity, proxy_for_global_id: '1234', proxy_for: double(title: 'title')) }
  let(:comment) { nil }
  it 'is deprecated' do
    expect(Deprecation).to receive(:warn).with(described_class, /^initialize is deprecated/, kind_of(Array))
    described_class.new(entity, nil, double, {})
  end
end
