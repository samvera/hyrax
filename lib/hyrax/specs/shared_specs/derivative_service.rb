RSpec.shared_examples 'a Hyrax::DerivativeService' do
  before do
    raise 'valid_file_set must be set with `let(:valid_file_set)`' unless
      defined? valid_file_set
  end

  subject { described_class.new(file_set) }
  let(:file_set) { valid_file_set }

  it { is_expected.to respond_to(:create_derivatives).with(1).arguments }

  it { is_expected.to respond_to(:cleanup_derivatives).with(0).arguments }

  it { is_expected.to respond_to(:file_set) }

  it { is_expected.to respond_to(:mime_type) }

  it { is_expected.to respond_to(:derivative_url).with(1).arguments }

  describe "#valid?" do
    context "when given a file_set it handles" do
      let(:file_set) { valid_file_set }
      it { is_expected.to be_valid }
    end
  end

  it "takes a fileset as an argument" do
    obj = described_class.new(valid_file_set)
    expect(obj.file_set).to eq valid_file_set
  end
end
