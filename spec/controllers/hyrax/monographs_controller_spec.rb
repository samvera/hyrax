# frozen_string_literal: true
# This tests the Hyrax::WorksControllerBehavior module with a Valkyrie resource.
RSpec.describe Hyrax::MonographsController do
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:user) { FactoryBot.create(:user, groups: 'admin') }

  before { sign_in user }

  describe "#update" do
    context "when updating work members" do
      let(:work) { FactoryBot.valkyrie_create(:comet_in_moominland, :with_member_works) }
      let(:child1) { Hyrax.query_service.find_by(id: work.member_ids.first) }
      let(:child2) { Hyrax.query_service.find_by(id: work.member_ids.last) }
      let(:child3) { FactoryBot.valkyrie_create(:monograph) }
      let(:attributes) do
        { '0' => { id: child1.id.to_s, _destroy: 'true' },
          '1' => { id: child3.id.to_s } }
      end

      before do
        # Suppress all event publishing to prevent listener side-effects from
        # failing the transaction. The Save and UpdateWorkMembers steps publish
        # events (object.metadata.updated, object.membership.updated) that
        # trigger synchronous listeners (MetadataIndexListener, etc.). If any
        # listener raises (e.g. Solr unavailable), the exception propagates
        # uncaught through the transaction and causes the update to silently
        # fail, returning Failure instead of Success.
        # Stubbing the index adapter alone is insufficient because exceptions
        # can originate from any listener in the chain.
        allow(Hyrax.publisher).to receive(:publish)
      end

      it "can add and remove children" do
        # Force evaluation of all children before the update request
        expect(work.member_ids.length).to eq 2
        child1
        child2
        child3

        patch :update, params: { id: work, monograph: { work_members_attributes: attributes } }
        expect(response).to be_redirect
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.member_ids).to contain_exactly(child_to_keep.id, child_to_add.id)
      end
    end
  end
end
