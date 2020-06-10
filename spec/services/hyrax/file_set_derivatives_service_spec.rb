# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::FileSetDerivativesService do
  let(:valid_file_set) do
    FileSet.new.tap do |f|
      allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
    end
  end

  subject { described_class.new(file_set) }

  it_behaves_like "a Hyrax::DerivativeService"
end
