require 'spec_helper'

describe CurationConcerns::CatalogHelper do
  before do
    helper.params[:controller] = 'catalog'
    allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(helper).to receive(:search_action_path) do |*args|
      catalog_index_path(*args)
    end
  end

  describe 'all_type_tab' do
    subject { helper.all_type_tab('All') }

    context 'when it is the active tab' do
      it { should eq "<li class=\"active\"><a href=\"#\">All</a></li>" }
    end

    context 'when it is not the active tab' do
      before do
        helper.params[:f] = { 'generic_type_sim' => ['Work'] }
      end
      it { should eq "<li><a href=\"/catalog\">All</a></li>" }
    end

    context 'when other parameters are present' do
      before do
        helper.params[:f] = { 'generic_type_sim' => ['Work'] }
        helper.params[:page] = 4
      end
      it('clears them') { should eq "<li><a href=\"/catalog\">All</a></li>" }
    end
  end

  describe 'type_tab' do
    subject { helper.type_tab('Works', 'Work') }

    context 'when it is the active tab' do
      before do
        helper.params[:f] = { 'generic_type_sim' => ['Work'] }
      end
      it { should eq "<li class=\"active\"><a href=\"#\">Works</a></li>" }
    end

    context 'when it is not the active tab' do
      it { should eq "<li><a href=\"/catalog?f%5Bgeneric_type_sim%5D%5B%5D=Work\">Works</a></li>" }
    end

    # context "when other parameters are present" do
    #   before do
    #     helper.params[:f] = { 'generic_type_sim' => ['Collection'] }
    #     helper.params[:page] = 4
    #   end
    #   it("should clear them") { should eq "<li><a href=\"/catalog?f%5Bgeneric_type_sim%5D%5B%5D=Work\">Works</a></li>" }
    # end
  end
end
