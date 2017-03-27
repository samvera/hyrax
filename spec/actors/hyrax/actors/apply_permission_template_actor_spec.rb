require 'spec_helper'

RSpec.describe Hyrax::Actors::ApplyPermissionTemplateActor do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
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
        expect(middleware.create(env)).to be true
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
        allow(terminator).to receive(:create).and_return(true)
      end

      it "adds the template users to the work" do
        expect(middleware.create(env)).to be true
        expect(work.edit_users).to include('hannah', 'Kevin')
        expect(work.edit_groups).to include 'librarians'
        expect(work.read_users).to include('gary', 'Taraji')
        expect(work.read_groups).to include 'readers'
      end
    end
  end
end
