# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::PermissionIndexer do
  let(:indexer_class) do
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::PermissionIndexer
    end
  end

  it_behaves_like 'a permission indexer'
end
