require 'spec_helper'

describe 'dashboard/_facet_limit.html.erb' do

  it "should draw facet links" do
    allow(view).to receive(:display_facet).and_return(double(items: [double(value: 'Audio', hits: 3), double(value: 'Video', hits:2)]))
    allow(view).to receive(:solr_field).and_return('desc_metadata__resource_type_sim')
    allow(view).to receive(:facet_limit_for).and_return(5)
    allow(view).to receive(:blacklight_config).and_return(DashboardController.blacklight_config)
    allow(view).to receive(:search_action_path).and_return('/search')
    allow(view).to receive(:params).and_return({controller: 'dashboard'})
    render
    expect(rendered).to include '<span class="facet-label"><a class="facet_select" href="/search">Audio</a></span><span class="facet-count">3</span>'
  end
end
