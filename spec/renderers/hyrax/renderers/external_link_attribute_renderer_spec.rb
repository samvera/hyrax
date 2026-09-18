# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::ExternalLinkAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['http://example.com']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      "<tr><th>Name</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute attribute-name\">"\
       "<a href=\"http://example.com\" target=\"_blank\" rel=\"noopener noreferrer\">"\
       "<span class='fa fa-external-link'></span>&nbsp;"\
       "http://example.com</a></li>\n" \
       "</ul></td></tr>"
    end

    it { expect(subject).to be_equivalent_to(expected) }

    it "opens links in a new tab" do
      link = subject.at_css("a")
      expect(link["target"]).to eq("_blank")
      expect(link["rel"]).to eq("noopener noreferrer")
    end
  end
end
