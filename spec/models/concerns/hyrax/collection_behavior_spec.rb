# frozen_string_literal: true

RSpec.describe Hyrax::CollectionBehavior, :active_fedora, :clean_repo do
  let(:collection) { create(:collection_lw) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

  describe "#destroy" do
    it "removes the collection id from associated members" do
      Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                              new_members: [work],
                                                              user: nil)
      collection.save

      collection_via_query = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: collection.id, use_valkyrie: false)

      expect { collection_via_query.destroy }
        .to change { Hyrax.query_service.find_by(id: work.id).member_of_collection_ids }
        .from([collection.id])
        .to([])
    end
  end
end
