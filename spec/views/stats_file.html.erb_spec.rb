require 'spec_helper'

# This test is named zzz_* because it contains hidden side-effects that affect subsequent
# test execution.  Specifically, the stub_model and render calls together.
# See: https://github.com/projecthydra/sufia/pull/1932

describe 'stats/file.html.erb', type: :view do
  describe 'usage statistics' do
    before :each do
      allow_message_expectations_on_nil
    end

    let(:no_stats) {
      double('FileUsage',
             created: Date.parse('2014-01-01'),
             total_pageviews: 0,
             total_downloads: 0,
             to_flot: [])
    }

    let(:stats) {
      double('FileUsage',
             created: Date.parse('2014-01-01'),
             total_pageviews: 9,
             total_downloads: 4,
             to_flot: [[1_396_422_000_000, 2], [1_396_508_400_000, 3], [1_396_594_800_000, 4]])
    }

    context 'when no analytics results returned' do
      before do
        assign(:stats, no_stats)
        assign(:pageviews, 0)
      end

      it 'shows 0 visits' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('div.alert-info', text: /0 views and 0 downloads since January 1, 2014/i, count: 1)
      end
    end

    context 'when results are returned' do
      before do
        assign(:stats, stats)
      end

      it 'shows visits' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('div.alert-info', text: /9 views and 4 downloads since January 1, 2014/i, count: 1)
      end
    end
  end
end
