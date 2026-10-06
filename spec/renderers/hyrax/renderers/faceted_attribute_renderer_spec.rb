# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::FacetedAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      %(
      <tr><th>Name</th>
      <td><ul class='tabular'>
      <li class="attribute attribute-name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Bob&locale=en">Bob</a></li>
      <li class="attribute attribute-name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Jessica&locale=en">Jessica</a></li>
      </ul></td></tr>
    )
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end

  describe "a controlled value with an indexed label" do
    let(:field) { :subject }
    let(:uri) { 'http://id.loc.gov/authorities/subjects/sh85077784' }
    let(:renderer) { described_class.new(field, [uri], labels: { uri => 'Livestock' }) }
    let(:rendered_link) { Nokogiri::HTML(renderer.render).at_css("a") }
    let(:query) { URI.parse(rendered_link['href']).query }

    it "links to the same facet the catalog sidebar uses" do
      expect(query).to include CGI.escape('f[subject_label_sim][]')
      expect(query).not_to include CGI.escape('f[subject_sim][]')
    end

    it "queries by the label, so the applied-filter chip reads the term" do
      expect(query).to include CGI.escape('Livestock')
      expect(query).not_to include CGI.escape(uri)
    end

    it "still shows the label as the link text" do
      expect(rendered_link.text).to eq 'Livestock'
    end
  end

  describe "a controlled value whose label facet is not registered" do
    let(:field) { :subject }
    let(:uri) { 'http://id.loc.gov/authorities/subjects/sh85077784' }
    let(:renderer) do
      described_class.new(field, [uri], labels: { uri => 'Livestock' }, label_facet_registered: false)
    end
    let(:query) { URI.parse(Nokogiri::HTML(renderer.render).at_css("a")['href']).query }

    it "links to the id facet, which is the one the catalog registered" do
      expect(query).to include CGI.escape('f[subject_sim][]')
      expect(query).to include CGI.escape(uri)
    end

    it "still shows the label as the link text" do
      expect(Nokogiri::HTML(renderer.render).at_css("a").text).to eq 'Livestock'
    end
  end

  describe "href generated" do
    describe "escaping" do
      let(:renderer) { described_class.new(field, ['John & Bob']) }
      let(:rendered_link) { Nokogiri::HTML(renderer.render).at_css("a") }
      let(:rendered_link_query) { URI.parse(rendered_link['href']).query }

      it "escapes content properly" do
        expect(rendered_link_query).to eq "#{CGI.escape('f[name_sim][]')}=#{CGI.escape('John & Bob')}&locale=en"
      end
    end
  end
end
