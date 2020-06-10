# frozen_string_literal: true
RSpec.describe Hyrax::DerivativePath do
  let(:id)     { '123' }
  let(:object) { double(id: id) }

  before { allow(Hyrax.config).to receive(:derivatives_path).and_return('tmp') }

  context "for a single path" do
    let(:destination_name) { 'thumbnail' }

    describe '.derivative_path_for_reference' do
      subject { described_class.derivative_path_for_reference(object, destination_name) }

      it { is_expected.to eq('tmp/12/3-thumbnail.jpeg') }
    end

    describe '#derivative_path' do
      context "with an object" do
        subject { described_class.new(object, destination_name).derivative_path }

        it { is_expected.to eq('tmp/12/3-thumbnail.jpeg') }
      end

      context "with an id" do
        subject { described_class.new(id, destination_name).derivative_path }

        it { is_expected.to eq('tmp/12/3-thumbnail.jpeg') }
      end
    end
  end

  context "for multiple paths" do
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

    describe ".derivatives_for_reference" do
      subject { described_class.derivatives_for_reference(object) }

      it { is_expected.to eq(["tmp/12/3-thumbnail.jpeg"]) }
    end

    describe "#all_paths" do
      context "with an object" do
        subject { described_class.new(object, nil).all_paths }

        it { is_expected.to eq(["tmp/12/3-thumbnail.jpeg"]) }
      end

      context "with an id" do
        subject { described_class.new(id, nil).all_paths }

        it { is_expected.to eq(["tmp/12/3-thumbnail.jpeg"]) }
      end
    end
  end
end
