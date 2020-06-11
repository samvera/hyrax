# frozen_string_literal: true
RSpec.describe Hyrax::Download, type: :model do
  it 'has an events metric' do
    expect(described_class.metrics).to be == Legato::ListParameter.new(:metrics, [:totalEvents])
  end

  it 'has dimensions' do
    expect(described_class.dimensions).to be == Legato::ListParameter.new(:dimensions, [:eventCategory, :eventAction, :eventLabel, :date])
  end

  it 'responds to :for_file' do
    expect(described_class).to respond_to(:for_file)
  end
end
