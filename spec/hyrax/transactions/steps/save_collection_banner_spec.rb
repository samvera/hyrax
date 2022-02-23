# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SaveCollectionBanner do
  subject(:step)   { described_class.new }
  let(:collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               title: "My Resource")
  end

  context 'update the banner info' do
    let(:uploaded) { FactoryBot.create(:uploaded_file) }

    it 'successfully updates the banner info' do
      expect(step.call(collection, update_banner_file_ids: [uploaded.id.to_s], banner_unchanged_indicator: false)).to be_success

      expect(CollectionBrandingInfo
             .where(collection_id: collection.id.to_s, role: "banner")
              .where("local_path LIKE '%#{uploaded.file.filename}'"))
        .to exist
    end
  end
end
