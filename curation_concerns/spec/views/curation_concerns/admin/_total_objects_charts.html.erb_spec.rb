require 'spec_helper'

describe 'curation_concerns/admin/_total_objects_charts.html.erb', type: :view do
  before do
    allow(view).to receive(:action_name).and_return(:index)
    assign(:resource_statistics, resource_stats)
    stub_template 'curation_concerns/admin/widgets/_pie.html.erb' => 'Mine 1'
  end
  let(:resource_stats) do
    instance_double(CurationConcerns::ResourceStatisticsSource,
                    open_concerns_count: 25,
                    authenticated_concerns_count: 300,
                    restricted_concerns_count: 777,
                    expired_embargo_now_authenticated_concerns_count: 66,
                    expired_embargo_now_open_concerns_count: 77,
                    active_embargo_now_authenticated_concerns_count: 88,
                    active_embargo_now_restricted_concerns_count: 99,
                    expired_lease_now_authenticated_concerns_count: 6666,
                    expired_lease_now_restricted_concerns_count: 7777,
                    active_lease_now_authenticated_concerns_count: 8888,
                    active_lease_now_open_concerns_count: 9999)
  end

  it "renders without error" do
    render
    expect(rendered).to have_content("Mine 1")
  end
end
