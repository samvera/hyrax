require 'spec_helper'

describe 'my/_index_partials/_list_works.html.erb' do

  let(:title) { 'Work Title' }
  let(:work) { FactoryGirl.create(:work, title: [title]) }
  let(:doc) { SolrDocument.new(work.to_solr) }

  let(:config) { My::FilesController.new.blacklight_config }

  before do
    allow(view).to receive(:blacklight_config) { config }
    render partial: 'my/_index_partials/list_works', locals: { document: doc }
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{work.id}")
    expect(rendered).to have_link title, href: sufia.generic_work_path(work)
    expect(rendered).to have_link 'Edit Work', href: sufia.edit_generic_work_path(work)
    expect(rendered).to have_link 'Delete Work', href: sufia.generic_work_path(work)
  end

end
