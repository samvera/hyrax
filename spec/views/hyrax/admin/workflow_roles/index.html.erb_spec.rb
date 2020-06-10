# frozen_string_literal: true
RSpec.describe 'hyrax/admin/workflow_roles/index.html.erb', type: :view do
  let!(:user1) { build(:user) }
  let!(:user2) { build(:user) }
  let(:agent_presenter) do
    instance_double(Hyrax::Admin::WorkflowRolesPresenter::AgentPresenter,
                    responsibilities_present?: responsibilities_exist)
  end

  let(:presenter) do
    instance_double(Hyrax::Admin::WorkflowRolesPresenter,
                    users: [user1, user2],
                    presenter_for: agent_presenter)
  end

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:admin_workflow_roles_path).and_return('/admin/workflow_roles')
  end

  context 'with no users having workflow roles' do
    let(:responsibilities_exist) { false }

    before { render }
    it 'displays "No Roles" for each user' do
      expect(rendered).to have_content('No roles', count: 2)
    end
  end

  context 'with some users having workflow roles' do
    let(:responsibilities_exist) { true }

    before do
      allow(agent_presenter).to receive(:responsibilities).and_return(["stuuf"])
      render
    end
    it 'displays roles for each user' do
      expect(rendered.match(/<ul>\s+<\/ul>/m)).to be nil
    end
  end
end
