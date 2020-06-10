# frozen_string_literal: true
RSpec.describe "hyrax/embargoes/index.html.erb", type: :view do
  before do
    stub_template 'hyrax/embargoes/_list_deactivated_embargoes' => 'rendered list_deactivated_embargoes'
    stub_template 'hyrax/embargoes/_list_expired_active_embargoes' => 'rendered list_expired_active_embargoes'
    stub_template 'hyrax/embargoes/_list_active_embargoes' => 'rendered list_active_embargoes'
  end

  it "displays the page and renderes deactivated, expired, and active embargoes" do
    render template: 'hyrax/embargoes/index'
    expect(rendered).to have_css('.tab-pane#active', text: 'rendered list_active_embargoes')
    expect(rendered).to have_css('.tab-pane#expired', text: 'rendered list_expired_active_embargoes')
    expect(rendered).to have_css('.tab-pane#deactivated', text: 'rendered list_deactivated_embargoes')
  end
end
