# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe GenericWorkResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource) { GenericWorkResource.new }

  it_behaves_like 'a Hyrax::Resource indexer'
end
