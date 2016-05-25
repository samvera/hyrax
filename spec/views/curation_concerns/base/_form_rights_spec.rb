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
    stub_const("Qa::Authorities::LocalSubauthority::AUTHORITIES_CONFIG", qa_fixtures)
  end

  context "when active and inactive rights are associated with a work" do
    before do
      curation_concern.rights = ['demo_id_01', 'demo_id_04']
      assign(:form, form)
      render inline: form_template, locals: { curation_concern: curation_concern }
    end

    it 'will only include active values if the current value is active' do
      expect(rendered).not_to have_xpath('//div/ul/li[1]/select/option[@value="demo_id_04"]')
      expect(rendered).not_to have_xpath('//div/ul/li[1]/select/option[text()="Fourth is an Inactive Term"]')
    end

    it 'will always include the current value as an option' do
      expect(rendered).to have_xpath('//div/ul/li[2]/select/option[@value="demo_id_04" and @selected="selected"]')
      expect(rendered).to have_xpath('//div/ul/li[2]/select/option[text()="Fourth is an Inactive Term"]')
    end

    it 'only offers active values to add to a work' do
      expect(rendered).not_to have_xpath('//div/ul/li[3]/select/option[@value="demo_id_04"]')
      expect(rendered).not_to have_xpath('//div/ul/li[3]/select/option[text()="Fourth is an Inactive Term"]')
    end
  end
end
