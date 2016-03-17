require 'spec_helper'

describe 'upload_sets/_metadata.html.erb' do
  let(:user) { build(:user) }
  let(:ability) { Ability.new(user) }
  let(:upload_set) { UploadSet.create }
  let(:form) { Sufia::UploadSetForm.new(upload_set, ability) }
  let(:work1) { build(:work, id: 'work1', title: ['First work']) }
  let(:work2) { build(:work, id: 'work2', title: ['Second work']) }

  let(:f) do
    allow(upload_set).to receive(:works).and_return([work1, work2])
    view.simple_form_for(form, url: '/update', builder: Sufia::FormBuilder) do |fs_form|
      return fs_form
    end
  end

  before do
    allow(view).to receive(:f).and_return(f)
    render
  end

  it "draws the form" do
    expect(rendered).to have_text 'Applies to all files just uploaded'
    expect(rendered).to have_css 'input[name="title[work1][]"][value="First work"]'
    expect(rendered).to have_css 'input[name="title[work2][]"][value="Second work"]'
  end
end
