describe Sufia::Download, type: :model do
  before do
    @download = described_class
  end

  it 'has an events metric' do
    expect(@download.metrics).to be == Legato::ListParameter.new(:metrics, [:totalEvents])
  end

  it 'has dimensions' do
    expect(@download.dimensions).to be == Legato::ListParameter.new(:dimensions, [:eventCategory, :eventAction, :eventLabel, :date])
  end

  it 'responds to :for_file' do
    expect(@download).to respond_to(:for_file)
  end
end
