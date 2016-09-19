require 'spec_helper'

RSpec.describe "_pie.html.erb" do
  let(:data) { { mine: 1, yours: 0 } }
  before do
    render "curation_concerns/admin/widgets/pie", data: data, label: 'my_pie'
  end

  it "makes a div with data and class" do
    expect(rendered).to have_css "div#my_pie-stats-pie.stats-pie"
    expect(rendered).to have_selector 'div[data-series]'
    expect(rendered).to have_selector 'div[data-label]'
    text = rendered.to_s
    expect(text).to include 'data-series="{&quot;drilldown&quot;:{&quot;series&quot;:[]},&quot;series&quot;:[{&quot;name&quot;:&quot;mine&quot;,&quot;y&quot;:1},{&quot;name&quot;:&quot;yours&quot;,&quot;y&quot;:0}]}"'
    expect(text).to include 'data-label="my_pie_data"'
  end
end
