require 'spec_helper'

describe 'generic_files/stats.html.erb' do
  describe 'usage statistics' do
    let(:generic_file) {
      stub_model(GenericFile, noid: '123',
        title: 'file1.txt')
    }

    before do
      assign(:generic_file, generic_file)
      assign(:created, Date.parse('2014-01-01'))
      assign(:stats_json, [].to_json)
    end

    it 'shows breadcrumbs' do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_selector('span.active', text: 'file1.txt')
    end

    context 'when no analytics results returned' do
      before do
        assign(:pageviews, 0)
      end

      it 'shows 0 visits' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('div.alert-info', text: /0 views since January 1, 2014/i, count: 1)
      end
    end

    context 'when results are returned' do
      before do
        assign(:stats_json, [[1396422000000,2],[1396508400000,3],[1396594800000,4]].to_json)
        assign(:pageviews, 9)
      end

      it 'shows visits' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('div.alert-info', text: /9 views since January 1, 2014/i, count: 1)
      end
    end
  end
end
