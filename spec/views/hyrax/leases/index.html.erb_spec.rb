# frozen_string_literal: true
RSpec.describe "hyrax/leases/index", type: :view do
  before do
    stub_template 'hyrax/leases/_list_deactivated_leases' => 'rendered list_deactivated_leases'
    stub_template 'hyrax/leases/_list_expired_active_leases' => 'rendered list_expired_active_leases'
    stub_template 'hyrax/leases/_list_active_leases' => 'rendered list_active_leases'
  end

  it "displays the page and renderes deactivated, expired, and active leases" do
    render template: 'hyrax/leases/index'
    expect(rendered).to have_css('.tab-pane#active', text: 'rendered list_active_leases')
    expect(rendered).to have_css('.tab-pane#expired', text: 'rendered list_expired_active_leases')
    expect(rendered).to have_css('.tab-pane#deactivated', text: 'rendered list_deactivated_leases')
  end
end
