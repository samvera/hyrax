describe 'curation_concerns/base/_form_relationships.html.erb', type: :view do
  let(:ability) { double }
  let(:work) { GenericWork.new }
  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end
  let(:service) { instance_double CurationConcerns::AdminSetService, select_options: [] }

  before do
    allow(view).to receive(:available_collections).and_return([])
    allow(view).to receive(:action_name).and_return('new')
    allow(CurationConcerns::AdminSetService).to receive(:new).with(controller).and_return(service)
  end

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "curation_concerns/base/form_relationships", f: f %>
      <% end %>
    )
  end

  let(:page) do
    assign(:form, form)
    render inline: form_template
    Capybara::Node::Simple.new(rendered)
  end

  context 'with assign_admin_set turned on' do
    before do
      allow(Flip).to receive(:assign_admin_set?).and_return(true)
    end

    it "draws the page" do
      expect(page).to have_content('Add as member of administrative set')
      expect(page).to have_selector('select#generic_work_admin_set_id')
    end
  end

  context 'with assign_admin_set disabled' do
    before do
      allow(Flip).to receive(:assign_admin_set?).and_return(false)
    end
    it 'draws the page, but not the admin set widget' do
      expect(page).not_to have_content('administrative set')
    end
  end
end
