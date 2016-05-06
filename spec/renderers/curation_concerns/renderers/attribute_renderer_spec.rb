require 'spec_helper'

describe CurationConcerns::Renderers::AttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }
  let(:yml_path) { File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'locales', '*.{rb,yml}') }
  before do
    I18n.load_path += Dir[File.join(yml_path)]
    I18n.reload!
  end
  after do
    I18n.load_path -= Dir[File.join(yml_path)]
    I18n.reload!
  end

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    context 'without microdata enabled' do
      before do
        CurationConcerns.config.display_microdata = false
      end
      let(:tr_content) {
        "<tr><th>Name</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute name\">Bob</li>\n" \
         "<li class=\"attribute name\">Jessica</li>\n" \
         "</ul></td></tr>"
      }
      it { expect(renderer).not_to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with an integer attribute' do
      let(:field) { :height }
      let(:renderer) { described_class.new(field, [567]) }
      let(:tr_content) do
        "<tr><th>Height</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute height\">567</li>\n" \
         "</ul></td></tr>"
      end

      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with microdata enabled' do
      before do
        CurationConcerns.config.display_microdata = true
      end
      let(:tr_content) {
        "<tr><th>Name</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute name\" itemscope itemtype=\"http://schema.org/Person\" itemprop=\"name\">" \
         "<span itemprop=\"firstName\">Bob</span></li>\n" \
         "<li class=\"attribute name\" itemscope itemtype=\"http://schema.org/Person\" itemprop=\"name\">" \
         "<span itemprop=\"firstName\">Jessica</span></li>\n" \
         "</ul></td></tr>"
      }
      it { expect(renderer).to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with links and < characters' do
      let(:field) { :description }
      let(:renderer) { described_class.new(field, ['Foo < Bar http://www.example.com. & More Text']) }
      let(:tr_content) do
        "<tr><th>Description</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute description\"><span itemprop=\"description\">Foo &lt; Bar <a href=\"http://www.example.com\">http://www.example.com</a>. &amp; More Text</span></li>\n" \
         "</ul></td></tr>"
      end

      it { expect(subject).to be_equivalent_to(expected) }
    end
  end
end
