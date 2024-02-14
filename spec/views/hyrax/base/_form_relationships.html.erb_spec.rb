# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_relationships.html.erb', type: :view do
  let(:ability) { double }
  let(:work) { FactoryBot.build(:monograph) }
  let(:form) do
    Hyrax::Forms::ResourceForm.for(resource: work).prepopulate!
  end
  let(:service) { instance_double Hyrax::AdminSetService }
  let(:presenter) { instance_double Hyrax::AdminSetOptionsPresenter, select_options: [] }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "hyrax/base/form_relationships", f: f %>
      <% end %>
    )
  end

  let(:page) do
    assign(:form, form)
    render inline: form_template
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(view).to receive(:action_name).and_return('new')
    allow(Hyrax::AdminSetService).to receive(:new).with(controller).and_return(service)
    allow(Hyrax::AdminSetOptionsPresenter).to receive(:new).with(service).and_return(presenter)
  end

  context 'with assign_admin_set turned on' do
    before do
      allow(Flipflop).to receive(:assign_admin_set?).and_return(true)
    end

    it "draws the page" do
      expect(page).to have_content('Administrative Set')
      expect(page).to have_selector('select#monograph_admin_set_id')
    end
  end

  context 'with assign_admin_set disabled' do
    before do
      allow(Flipflop).to receive(:assign_admin_set?).and_return(false)
    end
    it 'draws the page, but not the admin set widget' do
      expect(page).not_to have_content('administrative set')
    end
  end
end
