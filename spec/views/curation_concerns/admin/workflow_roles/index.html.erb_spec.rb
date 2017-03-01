require 'spec_helper'

describe 'curation_concerns/admin/workflow_roles/index.html.erb', type: :view do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let(:presenter) do
    CurationConcerns::Admin::WorkflowRolePresenter.new
  end

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:admin_workflow_roles_path).and_return('/admin/workflow_roles')
  end

  context 'with no users having workflow roles' do
    it 'displays "No Roles" for each user' do
      render
      expect(rendered).to have_content('No roles', count: 2)
    end
  end

  context 'with some users having workflow roles' do
    before do
      # Force user instances to have corresponding sipity agents
      user1.to_sipity_agent
      user2.to_sipity_agent
    end
    it 'displays roles for each user' do
      render
      expect(rendered.match(/<ul>\s+<\/ul>/m)).to be nil
    end
  end
end
