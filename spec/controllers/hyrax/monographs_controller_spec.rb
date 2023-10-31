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
      let(:children) { Hyrax.query_service.custom_queries.find_child_works(resource: work) }
      let(:child1) { children.to_a.first }
      let(:child2) { children.to_a.last }
      let(:child3) { FactoryBot.valkyrie_create(:monograph) }
      let(:attributes) do
        { '0' => { id: child1.id, _destroy: 'true' },
          '1' => { id: child3.id } }
      end

      it "can add and remove children" do
        patch :update, params: { id: work, monograph: { work_members_attributes: attributes } }
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.member_ids).to contain_exactly(child2.id, child3.id)
      end
    end
  end
end
