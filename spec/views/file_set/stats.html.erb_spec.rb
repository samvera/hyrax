require 'spec_helper'

describe 'file_sets/stats.html.erb', type: :view do
  describe 'usage statistics' do
    let(:file_set) {
      stub_model(FileSet, id: '123',
                          title: ['file1.txt'])
    }

    let(:no_stats) {
      allow_message_expectations_on_nil
      allow(FileUsage).to receive(:new)
      stub_model(FileUsage,
                 created: Date.parse('2014-01-01'),
                 total_pageviews: 0,
                 total_downloads: 0,
                 to_flot: []
                )
    }

    let(:stats) {
      allow(FileUsage).to receive(:new)
      stub_model(FileUsage,
                 created: Date.parse('2014-01-01'),
                 total_pageviews: 9,
                 total_downloads: 4,
                 to_flot: [[1_396_422_000_000, 2], [1_396_508_400_000, 3], [1_396_594_800_000, 4]]
                )
    }

    before do
      assign(:file_set, file_set)
      assign(:stats, no_stats)
    end

    context 'when no analytics results returned' do
      before do
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
