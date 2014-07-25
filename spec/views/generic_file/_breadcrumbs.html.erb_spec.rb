require 'spec_helper'

describe 'generic_files/_breadcrumbs.html.erb' do

  let(:request) { double("request", referer: referer) }
  let(:generic_file) { GenericFile.new(title: ["Fake object"]) }

  describe 'when coming from dashboard' do
    let! (:referer) { "http://...dashboard" }
    it "should link back to dashboard" do
      allow(view).to receive(:request).and_return(request)
      render partial: 'generic_files/breadcrumbs', locals: {include_file: false, generic_file: generic_file }
      expect(rendered).to have_link(t('sufia.bread_crumb.file_list'), sufia.dashboard_files_path)
    end
  end
  describe 'when coming from files list' do
    let! (:referer) { "http://...dashboard/files" }
    it "should link back to files list" do
      allow(view).to receive(:request).and_return(request)
      render partial: 'generic_files/breadcrumbs', locals: {include_file: false, generic_file: generic_file }
      expect(rendered).to have_link(t('sufia.bread_crumb.file_list'), sufia.dashboard_files_path)
    end
  end
  describe 'when coming from collections list' do
    let! (:referer) { "http://...dashboard/collections" }
    it "should link back to collections" do
      allow(view).to receive(:request).and_return(request)
      render partial: 'generic_files/breadcrumbs', locals: {include_file: false, generic_file: generic_file }
      expect(rendered).to have_link(t('sufia.bread_crumb.collections_list'), sufia.dashboard_collections_path)
    end
  end
end
