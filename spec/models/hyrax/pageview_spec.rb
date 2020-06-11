# frozen_string_literal: true
RSpec.describe Hyrax::Pageview, type: :model do
  it 'has a pageviews metric' do
    expect(described_class.metrics).to be == Legato::ListParameter.new(:metrics, [:pageviews])
  end

  it 'has a date dimension' do
    expect(described_class.dimensions).to be == Legato::ListParameter.new(:dimensions, [:date])
  end

  it 'responds to :for_path' do
    expect(described_class).to respond_to(:for_path)
  end
end
