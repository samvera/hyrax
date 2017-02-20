require 'spec_helper'
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::DerivativeService do
  let(:valid_file_set) { FileSet.new }
  subject { described_class.new(file_set) }
  it_behaves_like "a Hyrax::DerivativeService"
  before do
    @cached_services = described_class.services
  end
  after do
    described_class.services = @cached_services
  end

  describe ".services=" do
    it "allows you to set the available services" do
      described_class.services = [Hyrax::FileSetDerivativesService, Hyrax::FileSetDerivativesService]
      expect(described_class.services).to eq [Hyrax::FileSetDerivativesService, Hyrax::FileSetDerivativesService]
    end
    it "defaults to an array" do
      expect(described_class.services).to eq [Hyrax::FileSetDerivativesService]
    end
  end

  describe ".for" do
    before do
      described_class.services = [Hyrax::FileSetDerivativesService]
    end
    context "when a FileSet matches the requirements of a service" do
      let(:file_set) do
        FileSet.new.tap do |f|
          allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
        end
      end
      it "returns it" do
        expect(described_class.for(file_set)).to be_instance_of Hyrax::FileSetDerivativesService
      end
    end
    context "when a FileSet matches no services" do
      let(:file_set) { FileSet.new }
      it "returns a base DerivativeService" do
        expect(described_class.for(file_set)).to be_instance_of described_class
      end
    end
  end
end
