RSpec.describe 'records/edit_fields/_title.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/alt_title", f: f, key: 'description' %>
      <% end %>
    )
  end

  before do
    work.title = ["bbb", "aaa", "ccc"]
    work.alt_title = []
    assign(:form, form)
  end

  context "when there are 3 titles" do
    it 'hides the last 2 after alphabetizing all 3 titles' do
      render inline: form_template
      expect(rendered).to have_selector('input[type="hidden"][value="bbb"]', visible: false)
      expect(rendered).to have_selector('input[type="hidden"][value="ccc"]', visible: false)
    end
  end
end
