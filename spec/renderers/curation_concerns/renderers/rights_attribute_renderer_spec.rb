require 'spec_helper'

describe CurationConcerns::Renderers::RightsAttributeRenderer do
  let(:field) { :rights }
  let(:renderer) { described_class.new(field, ['http://creativecommons.org/licenses/by/3.0/us/', 'http://creativecommons.org/licenses/by-nd/3.0/us/']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Rights</th>\n" \
       "<td><ul class='tabular'>\n" \
       "<li class=\"attribute rights\"><a href=\"http://creativecommons.org/licenses/by/3.0/us/\" target=\"_blank\">Attribution 3.0 United States</a></li>\n" \
       "<li class=\"attribute rights\"><a href=\"http://creativecommons.org/licenses/by-nd/3.0/us/\" target=\"_blank\">Attribution-NoDerivs 3.0 United States</a></li>\n" \
       "</ul></td></tr>"
    }
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
