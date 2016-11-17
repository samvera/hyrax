require 'spec_helper'

describe 'curation_concerns/admin/_resource_stats.html.erb', type: :view do
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
    render partial: "curation_concerns/admin/resource_stats", locals: { resource_stats: resource_stats }
    expect(rendered).to have_content("Open Access25")
    expect(rendered).to have_content("Institution Name300")
    expect(rendered).to have_content("Private777")
    expect(rendered).to have_content("Embargo (Expired, Authenticated)66")
    expect(rendered).to have_content("Embargo (Expired, Open)77")
    expect(rendered).to have_content("Embargo (Active, Authenticated)88")
    expect(rendered).to have_content("Embargo (Active, Restricted)99")
    expect(rendered).to have_content("Lease (Active, Authenticated)8888")
    expect(rendered).to have_content("Lease (Active, Open)9999")
    expect(rendered).to have_content("Lease (Expired, Authenticated)6666")
    expect(rendered).to have_content("Lease (Expired, Restricted)7777")
  end
end
