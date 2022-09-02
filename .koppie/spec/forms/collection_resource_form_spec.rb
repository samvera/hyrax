# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource CollectionResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe CollectionResourceForm do
  let(:change_set) { described_class.new(resource) }
  let(:resource)   { CollectionResource.new }

  it_behaves_like 'a Valkyrie::ChangeSet'
end
