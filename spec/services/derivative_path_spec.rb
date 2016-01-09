require 'spec_helper'

describe CurationConcerns::DerivativePath do
  before do
    allow(CurationConcerns.config).to receive(:derivatives_path).and_return('tmp')
  end

  describe '.derivative_path_for_reference' do
    subject { described_class.derivative_path_for_reference(object, destination_name) }

    let(:object) { double(id: '123') }
    let(:destination_name) { 'thumbnail' }

    it { is_expected.to eq 'tmp/12/3-thumbnail.jpeg' }
  end

  describe "#derivatives_for_reference" do
    subject { described_class.derivatives_for_reference(object) }
    before do
      FileUtils.mkdir_p("tmp/12")
      File.open("tmp/12/3-thumbnail.jpeg", 'w') do |f|
        f.write "test"
      end
      File.open("tmp/12/4-thumbnail.jpeg", 'w') do |f|
        f.write "test"
      end
    end
    after do
      FileUtils.rm_rf("tmp/12")
    end

    let(:object) { double(id: '123') }

    it "lists all the paths to derivatives" do
      expect(subject).to eq [
        "tmp/12/3-thumbnail.jpeg"
      ]
    end
  end
end
