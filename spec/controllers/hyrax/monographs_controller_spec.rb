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
      # Use sort_by to avoid order-dependent flakiness: find_child_works does not guarantee order
      let(:child_works) { Hyrax.query_service.custom_queries.find_child_works(resource: work).to_a.sort_by(&:id) }
      let(:child_to_remove) { child_works.first }
      let(:child_to_keep) { child_works.last }
      let(:child_to_add) { FactoryBot.valkyrie_create(:monograph) }
      let(:attributes) do
        { '0' => { id: child_to_remove.id, _destroy: 'true' },
          '1' => { id: child_to_add.id } }
      end

      it "can add and remove children" do
        patch :update, params: { id: work, monograph: { work_members_attributes: attributes } }
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.member_ids).to contain_exactly(child_to_keep.id, child_to_add.id)
      end
    end
  end
end
