RSpec.shared_examples 'a Hyrax::DerivativeService' do
  before do
    raise 'file_set must be set with `let(:file_set)`' unless
      defined? file_set
  end
  it { is_expected.to respond_to(:create_derivatives).with(1).arguments }

  it { is_expected.to respond_to(:cleanup_derivatives).with(0).arguments }

  it { is_expected.to respond_to(:file_set) }

  it { is_expected.to respond_to(:mime_type) }

  it { is_expected.to respond_to(:derivative_url).with(1).arguments }

  it "takes a fileset as an argument" do
    obj = described_class.new(file_set)
    expect(obj.file_set).to eq file_set
  end
end
