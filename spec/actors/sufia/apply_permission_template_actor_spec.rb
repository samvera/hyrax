require 'spec_helper'

RSpec.describe Sufia::ApplyPermissionTemplateActor do
  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           update: true,
                           user: depositor)
  end
  let(:actor) do
    CurationConcerns::Actors::ActorStack.new(work, depositor, [described_class])
  end
  let(:depositor) { create(:user) }
  let(:work) { build(:generic_work) }
  let(:attributes) { { admin_set_id: admin_set.id } }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

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
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: 'hannah',
               access: 'manage')
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'librarians',
               access: 'manage')
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: 'gary',
               access: 'view')
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'readers',
               access: 'view')
        allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(create_actor)
        allow(create_actor).to receive(:create).and_return(true)
      end

      it "adds the template users to the work" do
        expect(actor.create(attributes)).to be true
        expect(work.edit_users).to include 'hannah'
        expect(work.edit_groups).to include 'librarians'
        expect(work.read_users).to include 'gary'
        expect(work.read_groups).to include 'readers'
      end
    end
  end
end
