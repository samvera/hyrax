require 'spec_helper'

describe 'curation_concerns/base/unavailable.html.erb', type: :view do
  let(:model) do
    double('model',
           persisted?: true,
           to_param: '123',
           model_name: GenericWork.model_name)
  end
  let(:workflow) do
    double('workflow', state: 'deposited', state_label: 'really deposited')
  end
  let(:presenter) do
    double('presenter',
           to_s: 'super cool',
           workflow: workflow,
           human_readable_type: 'Generic Work')
  end
  let(:parent_presenter) do
    double('parent_presenter',
           to_s: 'parental remark',
           to_model: model,
           human_readable_type: 'Foo Bar')
  end
  before do
    assign(:presenter, presenter)
    assign(:parent_presenter, parent_presenter)
    stub_template 'shared/_brand_bar.html.erb' => ''
    stub_template 'shared/_title_bar.html.erb' => ''
    flash[:notice] = I18n.t("curation_concerns.workflow.unauthorized")
    render template: 'curation_concerns/base/unavailable.html.erb', layout: 'layouts/curation_concerns'
  end
  it "renders with the flash message" do
    expect(rendered).to have_content 'super cool'
    expect(rendered).to have_content 'really deposited'
    expect(rendered).to have_content 'parental remark'
    expect(rendered).to have_content 'Generic Work'
    expect(rendered).to have_content 'The work is not currently available because it has not yet completed the approval process'
  end
end
