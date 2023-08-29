# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::FileSetDerivativesService do
  context 'for active_fedora', :active_fedora do
    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return('image/png')
      end
    end

    it_behaves_like "a Hyrax::DerivativeService"
  end

  context 'for a valkyrie resource', valkyrie_adapter: :test_adapter do
    let(:valid_file_set) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :image)
    end

    it_behaves_like "a Hyrax::DerivativeService"
  end
end
