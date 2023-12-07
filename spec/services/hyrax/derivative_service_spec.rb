# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

# NOTE: This service class is marked for deprecation. The new Hyrax::FileSetDerivativesService is preferred and can handle
#   both ActiveFedora and Valkyrie objects.
RSpec.describe Hyrax::DerivativeService, :active_fedora do
  let(:valid_file_set) { FileSet.new }

  subject { described_class.new(file_set) }

  it_behaves_like "a Hyrax::DerivativeService"

  describe ".for" do
    context "when a FileSet matches the requirements of a service" do
      let(:file_set) do
        FileSet.new.tap do |f|
          allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
        end
      end

      it "returns it" do
        expect(described_class.for(file_set, services: [Hyrax::FileSetDerivativesService])).to be_instance_of Hyrax::FileSetDerivativesService
      end
    end
    context "when a FileSet matches no services" do
      let(:file_set) { FileSet.new }

      it "returns a base DerivativeService" do
        expect(described_class.for(file_set, services: [Hyrax::FileSetDerivativesService])).to be_instance_of described_class
      end
    end
  end
end
