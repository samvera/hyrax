require 'spec_helper'

RSpec.describe Hyrax::ApplyPermissionTemplateActor do
  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           update: true,
                           user: depositor)
  end
  let(:actor) do
    Hyrax::Actors::ActorStack.new(work, ::Ability.new(depositor), [described_class])
  end
  let(:depositor) { create(:user) }
  let(:work) do
    build(:generic_work,
          edit_users: ['Kevin'],
          read_users: ['Taraji'])
  end
  let(:attributes) { { admin_set_id: admin_set.id } }
  let(:admin_set) { create(:admin_set, with_permission_template: true) }
  let(:permission_template) { admin_set.permission_template }

  describe "create" do
    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }

      it "returns true" do
        expect(actor.create(attributes)).to be true
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }
      before do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: 'hannah')
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'librarians')
        create(:permission_template_access,
               :view,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: 'gary')
        create(:permission_template_access,
               :view,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'readers')
        allow(Hyrax::Actors::RootActor).to receive(:new).and_return(create_actor)
        allow(create_actor).to receive(:create).and_return(true)
      end

      it "adds the template users to the work" do
        expect(actor.create(attributes)).to be true
        expect(work.edit_users).to include('hannah', 'Kevin')
        expect(work.edit_groups).to include 'librarians'
        expect(work.read_users).to include('gary', 'Taraji')
        expect(work.read_groups).to include 'readers'
      end
    end
  end
end
