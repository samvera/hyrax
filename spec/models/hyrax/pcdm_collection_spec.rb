# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::PcdmCollection do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::PcdmCollection'

  describe '#name' do
    it 'uses a Collection-like name' do
      expect(subject.model_name)
        .to have_attributes(human: "Collection",
                            i18n_key: :collection,
                            param_key: "collection",
                            plural: "collections",
                            route_key: "collections",
                            singular_route_key: "collection")
    end
  end

  describe '#human_readable_type' do
    it 'has a human readable type' do
      expect(collection.human_readable_type).to eq 'Collection'
    end
  end
end
