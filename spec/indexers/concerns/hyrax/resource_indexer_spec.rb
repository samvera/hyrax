# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ResourceIndexer do
  let(:resource) { Hyrax::Resource.new }
  let(:indexer_class) do
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::ResourceIndexer
    end
  end

  it_behaves_like 'a Hyrax::Resource indexer'
end
