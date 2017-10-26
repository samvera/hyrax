RSpec.describe 'hyrax/base/_form_metadata.html.erb', type: :view do
  before do
    allow(change_set).to receive(:display_additional_fields?).and_return(additional_fields)
  end
  let(:work) { GenericWork.new }
  let(:change_set) do
    GenericWorkChangeSet.new(work)
  end

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "hyrax/base/form_metadata", f: f %>
      <% end %>
     )
  end

  let(:page) do
    assign(:change_set, change_set)
    render inline: form_template
    Capybara::Node::Simple.new(rendered)
  end

  context 'with secondary terms' do
    let(:additional_fields) { true }

    it "renders the additional fields button" do
      expect(page).to have_content('Additional fields')
    end
  end

  context 'without secondary terms' do
    let(:additional_fields) { false }

    it 'does not render the addtional fields button' do
      expect(page).not_to have_content('Additional fields')
    end
  end
end
