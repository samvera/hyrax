require 'spec_helper'

RSpec.describe "_doughnut.html.erb" do
  let(:data) { { mine: 1, yours: 0 } }
  before do
    render "curation_concerns/admin/widgets/doughnut", data: data, label: 'my_pie'
  end

  it "makes a div with data and class" do
    expect(rendered).to have_css "div#my_pie-stats-doughnut.stats-doughnut"
    expect(rendered).to have_selector 'div[data-flot]'
    expect(rendered).to have_selector 'div[data-label]'
    text = rendered.to_s
    expect(text).to include 'data-flot="[{&quot;label&quot;:&quot;mine&quot;,&quot;data&quot;:1},{&quot;label&quot;:&quot;yours&quot;,&quot;data&quot;:0}]"'
    expect(text).to include 'data-label="my_pie_data"'
  end
end
