require 'spec_helper'

describe CurationConcerns::AttributeRenderer do
  let(:renderer) { described_class.new(:name, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { renderer.render }

    it { is_expected.to eq "<tr><th>Name</th>\n" \
       "<td><ul class='tabular'><li class=\"attribute name\">Bob</li>\n" \
       "<li class=\"attribute name\">Jessica</li>\n" \
       "</ul></td></tr>" }
  end
end
