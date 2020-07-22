# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::VisibilityIndexer do
  let(:indexer_class) do
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::VisibilityIndexer
    end
  end
  let(:resource) { Hyrax::Resource.new }

  it_behaves_like 'a visibility indexer'
end
