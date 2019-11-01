# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::CoreMetadataIndexer do
  let(:indexer_class) do
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::CoreMetadataIndexer
    end
  end

  it_behaves_like 'a Core metadata indexer'
end
