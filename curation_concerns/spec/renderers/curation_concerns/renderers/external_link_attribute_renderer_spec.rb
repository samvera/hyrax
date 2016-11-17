require 'spec_helper'

describe CurationConcerns::Renderers::ExternalLinkAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['http://example.com']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Name</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute name\">"\
       "<a href=\"http://example.com\">"\
       "<span class='glyphicon glyphicon-new-window'></span>&nbsp;"\
       "http://example.com</a></li>\n" \
       "</ul></td></tr>"
    }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
