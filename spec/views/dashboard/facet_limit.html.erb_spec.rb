require 'spec_helper'

describe 'dashboard/_facet_limit.html.erb' do

  it "should draw facet links" do
    allow(view).to receive(:display_facet).and_return(double(items: [double(value: 'Audio', hits: 3), double(value: 'Video', hits:2)]))
    allow(view).to receive(:solr_field).and_return('desc_metadata__resource_type_sim')
    allow(view).to receive(:facet_limit_for).and_return(5)
    allow(view).to receive(:blacklight_config).and_return(DashboardController.blacklight_config)
    allow(view).to receive(:params).and_return({controller: 'dashboard'})
    render
    expect(rendered).to match /<a class="facet_select" href="\/dashboard\?f%5Bdesc_metadata__resource_type_sim%5D%5B%5D=Audio">Audio<\/a> <span class="count">3<\/span>/

  end
end
