# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource Image`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe ImageIndexer do
  let(:resource) { Image.new }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Hyrax::Resource indexer'
end
