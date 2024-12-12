# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SaveCollectionLogo do
  subject(:step)   { described_class.new }
  let(:collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               title: "My Resource")
  end

  context 'update collection logo metadta' do
    let(:uploaded) { FactoryBot.create(:uploaded_file) }

    it 'saves logo metadata' do
      expect(step.call(collection,
                       update_logo_file_ids: [uploaded.id.to_s],
                       alttext_values: ["Logo alt Text"],
                       linkurl_values: ["http://abc.com"],
                       logo_unchanged_indicator: false)).to be_success

      expect(CollectionBrandingInfo
               .where(collection_id: collection.id.to_s,
                      role: "logo",
                      alt_text: "Logo alt Text",
                      target_url: "http://abc.com")
               .where("local_path LIKE '%#{uploaded.file.filename}'"))
        .to exist
    end

    it 'does not save linkurl containing html; target_url is empty' do
      expect(step.call(collection,
                       update_logo_file_ids: [uploaded.id.to_s],
                       alttext_values: ["Logo alt Text"],
                       linkurl_values: ["<script>remove_me</script>"],
                       logo_unchanged_indicator: false)).to be_success

      expect(
        CollectionBrandingInfo.where(
          collection_id: collection.id.to_s,
          target_url: "<script>remove_me</script>"
        ).where("target_url LIKE '%remove_me%)'")
      ).not_to exist
    end

    it 'does not save linkurl containing dodgy protocol; target_url is empty' do
      expect(step.call(collection,
                       update_logo_file_ids: [uploaded.id.to_s],
                       alttext_values: ["Logo alt Text"],
                       linkurl_values: ['javascript:alert("remove_me")'],
                       logo_unchanged_indicator: false)).to be_success

      expect(
        CollectionBrandingInfo.where(
          collection_id: collection.id.to_s,
          target_url: 'javascript:alert("remove_me")'
        ).where("target_url LIKE '%remove_me%)'")
      ).not_to exist
    end
  end
end
