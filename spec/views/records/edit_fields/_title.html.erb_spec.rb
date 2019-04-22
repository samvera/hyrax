RSpec.describe 'records/edit_fields/_title.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/title", f: f, key: 'description' %>
      <% end %>
    )
  end

  before do
    work.title = ["ccc", "bbb", "aaa"]
    assign(:form, form)
  end

  context "when there are 3 titles" do
    it 'displays the first after alphabetizing the list' do
      render inline: form_template
      expect(rendered).to have_selector('input[class="form-control string required"][value="aaa"]')
    end
  end
end
