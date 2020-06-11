# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/_sidebar.html.erb', type: :view do
  let(:user) { stub_model(User, user_key: 'mjg', name: 'Foobar') }
  let(:read_admin_dashboard) { false }
  let(:manage_any_admin_set) { false }
  let(:review_submissions) { false }
  let(:manage_user) { false }
  let(:update_appearance) { false }
  let(:manage_feature) { false }
  let(:manage_workflow) { false }
  let(:manage_collection_types) { false }

  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    assign(:user, user)
    allow(view).to receive(:can?).with(:read, :admin_dashboard).and_return(read_admin_dashboard)
    allow(view).to receive(:can?).with(:manage_any, AdminSet).and_return(manage_any_admin_set)
    allow(view).to receive(:can?).with(:review, :submissions).and_return(review_submissions)
    allow(view).to receive(:can?).with(:manage, User).and_return(manage_user)
    allow(view).to receive(:can?).with(:update, :appearance).and_return(update_appearance)
    allow(view).to receive(:can?).with(:manage, Hyrax::Feature).and_return(manage_feature)
    allow(view).to receive(:can?).with(:manage, Sipity::WorkflowResponsibility).and_return(manage_workflow)
    allow(view).to receive(:can?).with(:manage, :collection_types).and_return(manage_collection_types)
  end

  context 'with any user' do
    before { render }
    subject { rendered }

    it { is_expected.to have_content 'Foobar' }
    it { is_expected.to have_content t('hyrax.admin.sidebar.activity') }
    it { is_expected.to have_content t('hyrax.admin.sidebar.user_activity') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.profile') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.notifications') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.transfers') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.collections') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.works') }
  end

  context 'with a user who can read the admin dash' do
    let(:read_admin_dashboard) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_link t('hyrax.admin.sidebar.statistics') }
    it { is_expected.to have_link t('hyrax.embargoes.index.manage_embargoes') }
    it { is_expected.to have_link t('hyrax.leases.index.manage_leases') }
  end

  context 'with a user who can review submissions' do
    let(:review_submissions) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_link t('hyrax.admin.sidebar.workflow_review') }
  end

  context 'with a user who can manage users' do
    let(:manage_user) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_link t('hyrax.admin.sidebar.users') }
  end

  context 'with a user who can update appearance' do
    let(:update_appearance) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_content t('hyrax.admin.sidebar.configuration') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.appearance') }
  end

  context 'with a user who can manage features' do
    let(:manage_feature) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_content t('hyrax.admin.sidebar.configuration') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.pages') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.content_blocks') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.technical') }
  end

  context 'with a user who can manage workflow' do
    let(:manage_workflow) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_content t('hyrax.admin.sidebar.configuration') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.workflow_roles') }
  end

  context 'with a user who can manage collection types' do
    let(:manage_collection_types) { true }

    before { render }
    subject { rendered }

    it { is_expected.to have_content t('hyrax.admin.sidebar.configuration') }
    it { is_expected.to have_link t('hyrax.admin.sidebar.collection_types') }
  end

  context 'when proxy deposits are enabled' do
    before do
      allow(Flipflop).to receive(:proxy_deposit?).and_return(true)
      render
    end

    subject { rendered }

    it { is_expected.to have_link t('hyrax.dashboard.manage_proxies') }
  end

  context 'when proxy deposits are disabled' do
    before do
      allow(Flipflop).to receive(:proxy_deposit?).and_return(false)
      render
    end

    subject { rendered }

    it { is_expected.not_to have_link t('hyrax.dashboard.manage_proxies') }
  end

  context 'when sidebar partials are configured' do
    around do |example|
      original_partials = Hyrax::DashboardController.sidebar_partials.deep_dup
      example.call
      Hyrax::DashboardController.sidebar_partials = original_partials
    end

    # Show configuration menu
    let(:manage_feature) { true }

    it 'renders custom activity partials' do
      stub_template "hyrax/dashboard/sidebar/_custom_activity.html.erb" => "Custom Activity Item"
      Hyrax::DashboardController.sidebar_partials[:activity] << "hyrax/dashboard/sidebar/custom_activity"
      render
      expect(rendered).to have_content "Custom Activity Item"
    end

    it 'renders custom configuration partials' do
      stub_template "hyrax/dashboard/sidebar/_custom_configuration.html.erb" => "Custom Configuration Item"
      Hyrax::DashboardController.sidebar_partials[:configuration] << "hyrax/dashboard/sidebar/custom_configuration"
      render
      expect(rendered).to have_content "Custom Configuration Item"
    end

    it 'renders custom repository content partials' do
      stub_template "hyrax/dashboard/sidebar/_custom_repository_content.html.erb" => "Custom Repository Content Item"
      Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/custom_repository_content"
      render
      expect(rendered).to have_content "Custom Repository Content Item"
    end

    it 'renders custom tasks partials' do
      stub_template "hyrax/dashboard/sidebar/_custom_task.html.erb" => "Custom Task Item"
      Hyrax::DashboardController.sidebar_partials[:tasks] << "hyrax/dashboard/sidebar/custom_task"
      render
      expect(rendered).to have_content "Custom Task Item"
    end
  end
end
