require 'spec_helper'

describe 'curation_concerns/base/_form_rights.html.erb' do
  let(:curation_concern) { GenericWork.new }
  let(:form) { CurationConcerns::Forms::WorkForm.new(curation_concern, nil) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "curation_concerns/base/form_rights", f: f, curation_concern: curation_concern %>
      <% end %>
    )
  end

  before do
    qa_fixtures = { local_path: File.expand_path('../../../../fixtures/authorities', __FILE__) }
    allow(Qa::Authorities::Local).to receive(:config).and_return(qa_fixtures)
  end

  context "when active and inactive rights are associated with a work" do
    before do
      curation_concern.rights = ['demo_id_01', 'demo_id_04']
      assign(:form, form)
      render inline: form_template, locals: { curation_concern: curation_concern }
    end

    it 'will only include inactive values if the current value is inactive' do
      # only one of the select boxes will have the inactive rights statement
      expect(rendered).to have_xpath('//option[@value="demo_id_04"]', count: 1)
      # and it will be the selected option.
      expect(rendered).to have_xpath('//option[@value="demo_id_04" and @selected]', count: 1)

      # the active values will be available in each select box
      expect(rendered).to have_xpath('//option[@value="demo_id_01"]', count: 3)
      # and one will be selected
      expect(rendered).to have_xpath('//option[@value="demo_id_01" and @selected]', count: 1)
    end

    it 'only offers active values to add to a work' do
      expect(rendered).not_to have_xpath('//div/ul/li[3]/select/option[@value="demo_id_04"]')
      expect(rendered).not_to have_xpath('//div/ul/li[3]/select/option[text()="Fourth is an Inactive Term"]')
    end
  end
end
