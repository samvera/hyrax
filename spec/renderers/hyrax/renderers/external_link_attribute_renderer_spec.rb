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

  describe "a controlled value whose label is indexed" do
    subject(:link) { Nokogiri::HTML(labeled_renderer.render).at_css('a') }

    let(:uri) { 'http://creativecommons.org/licenses/by/3.0/us/' }
    let(:labeled_renderer) do
      described_class.new(:license, [uri], labels: { uri => 'Attribution 3.0 United States' })
    end

    it "shows the term label as the link text" do
      expect(link.text.strip).to eq 'Attribution 3.0 United States'
    end

    it "links to the stored id" do
      expect(link['href']).to eq uri
    end

    it "opens in a new tab" do
      expect(link['target']).to eq '_blank'
      expect(link['rel']).to eq 'noopener noreferrer'
    end

    it "keeps the external link icon" do
      expect(Nokogiri::HTML(labeled_renderer.render).at_css('span.fa-external-link')).to be_present
    end
  end

  describe "a controlled value whose id is not a URI" do
    subject(:rendered) { Nokogiri::HTML(renderer.render) }

    let(:renderer) { described_class.new(:resource_type, ['oer'], labels: { 'oer' => 'OER' }) }

    it "shows the label as plain text" do
      expect(rendered.css('li').text).to include 'OER'
    end

    it "emits no link, since the id is not a linkable target" do
      expect(rendered.at_css('a')).to be_nil
    end
  end

  describe "a controlled value carrying an unsafe scheme" do
    subject(:rendered) { Nokogiri::HTML(renderer.render) }

    let(:uri) { 'javascript:alert(1)' }
    let(:renderer) { described_class.new(:license, [uri], labels: { uri => 'Bad' }) }

    it "does not link it" do
      expect(rendered.at_css('a')).to be_nil
    end
  end

  describe "a controlled value with no indexed label" do
    let(:uri) { 'http://creativecommons.org/licenses/by/3.0/us/' }
    let(:unlabeled_renderer) { described_class.new(:license, [uri], labels: {}) }

    it "renders the value as it did before labels were indexed" do
      expect(Nokogiri::HTML(unlabeled_renderer.render).at_css('a').text).to include uri
    end
  end
end
