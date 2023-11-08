# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_share.html.erb', type: :view do
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user) }
  let(:user) { stub_model(User) }
  let(:work) { GenericWork.new }
  let(:form) { Hyrax.config.disable_wings ? Hyrax::Forms::ResourceForm.for(resource: work) : Hyrax::GenericWorkForm.new(work, ability, controller) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "hyrax/base/form_share", f: f %>
      <% end %>
    )
  end

  let(:rendered_save) do
    # explicitly save rendered, as it seems to become empty at some point during processing
    assign(:form, form)
    render inline: form_template
  end

  let(:page) do
    Capybara::Node::Simple.new(rendered_save)
  end

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:action_name).and_return('new')
  end

  it "renders the permissions save note" do
    expect(page).to have_selector('div#save_perm_note', visible: false)
    expect(rendered_save).to include I18n.t("hyrax.base.form_share.permissions_save_note_html")
  end
  it "renders the add this group" do
    expect(rendered_save).to include I18n.t("hyrax.base.form_share.add_this_group_html")
  end
end
