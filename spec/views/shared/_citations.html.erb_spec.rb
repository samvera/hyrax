# frozen_string_literal: true
RSpec.describe 'shared/_citations.html.erb', type: :view do
  let(:work_solr_document) do
    SolrDocument.new(id: '999',
                     title_tesim: ['My Title'],
                     creator_tesim: ['Doe, John', 'Doe, Jane'],
                     date_modified_dtsi: '2011-04-01',
                     has_model_ssim: ['GenericWork'],
                     depositor_tesim: depositor.user_key,
                     description_tesim: ['Lorem ipsum lorem ipsum.'],
                     keyword_tesim: ['bacon', 'sausage', 'eggs'],
                     rights_statement_tesim: ['http://example.org/rs/1'],
                     rights_notes_tesim: ['Notes on the rights'],
                     date_created_tesim: ['1984-01-02'],
                     publisher_tesim: ['French Press'])
  end

  let(:file_set_solr_document) do
    SolrDocument.new(id: '123',
                     title_tesim: ['My FileSet'],
                     depositor_tesim: depositor.user_key)
  end

  let(:ability) { double }

  let(:request) { double('request', host: 'test.host') }

  let(:depositor) do
    stub_model(User,
               user_key: 'bob',
               twitter_handle: 'bot4lib')
  end

  let(:presenter) do
    Hyrax::WorkShowPresenter.new(work_solr_document, ability, request)
  end

  let(:representative_presenter) do
    Hyrax::FileSetPresenter.new(file_set_solr_document, ability)
  end

  before do
    assign(:presenter, presenter)
    allow(presenter).to receive(:representative_presenter).and_return(representative_presenter)
  end

  describe 'content for google scholar' do
    let(:content) { view.content_for(:gscholar_meta) }
    context 'with a full record' do
      let(:expected_meta_tags) do
        {
          'description' => 'Lorem ipsum lorem ipsum.',
          'citation_title' => 'My Title',
          'citation_publication_date' => '1984-01-02',
          'citation_pdf_url' => 'http://test.host/downloads/123',
          'citation_keywords' => 'bacon; sausage; eggs',
          'citation_publisher' => 'French Press',
          'citation_dissertation_institution' => 'University of Strasbourg; University of Heidelberg'
        }
      end

      let(:expected_authors) { ['Doe, John', 'Doe, Jane'] }

      before do
        allow(presenter).to receive(:degree_grantor).and_return(["University of Strasbourg", "University of Heidelberg"])
        render partial: 'shared/citations', locals: { presenter: presenter }
      end

      it 'appears in meta tags' do
        gscholar_meta_tags = Nokogiri::HTML(content).xpath("//meta[contains(@name, 'citation_')]")
        expect(gscholar_meta_tags.count).to eq(8)
      end

      it 'displays the spectrum of meta data tags' do
        doc = Nokogiri::HTML(content)
        expected_meta_tags.each do |name, expected_value|
          tag = doc.xpath("//meta[@name='#{name}']")
          expect(tag.attribute('content').value).to eq(expected_value),
            "Expected meta tag '#{name}' to have content '#{expected_value}'"
        end

        author_tags = doc.xpath("//meta[@name='citation_author']")
        expect(author_tags.map { |t| t.attribute('content').value }).to eq(expected_authors)
      end
    end

    context 'with a journal article' do
      let(:expected_meta_tags) do
        {
          'citation_journal_title' => 'My cool journal',
          'citation_volume' => 'III',
          'citation_issue' => '23',
          'citation_firstpage' => '112',
          'citation_lastpage' => '135'
        }
      end

      before do
        allow(presenter).to receive(:journal_title).and_return('My cool journal')
        allow(presenter).to receive(:journal_volume).and_return('III')
        allow(presenter).to receive(:journal_issue).and_return('23')
        allow(presenter).to receive(:page_start).and_return('112')
        allow(presenter).to receive(:page_end).and_return('135')
        render partial: 'shared/citations', locals: { presenter: presenter }
      end
      it 'displays the spectrum of meta data tags' do
        doc = Nokogiri::HTML(content)
        expected_meta_tags.each do |name, expected_value|
          tag = doc.xpath("//meta[@name='#{name}']")
          expect(tag.attribute('content').value).to eq(expected_value),
            "Expected meta tag '#{name}' to have content '#{expected_value}'"
        end
      end
    end

    context 'with minimal record' do
      let(:work_solr_document) do
        SolrDocument.new(id: '999',
                         title_tesim: ['My Title'],
                         date_modified_dtsi: '2011-04-01',
                         has_model_ssim: ['GenericWork'],
                         depositor_tesim: depositor.user_key)
      end
      let(:representative_presenter) { nil }

      before do
        render partial: 'shared/citations', locals: { presenter: presenter }
      end

      it 'appears in meta tags' do
        gscholar_meta_tags = Nokogiri::HTML(content).xpath("//meta[contains(@name, 'citation_')]")
        expect(gscholar_meta_tags.count).to eq(1)
      end

      it 'displays only title metadata' do
        doc = Nokogiri::HTML(content)

        tag = doc.xpath("//meta[@name='description']")
        expect(tag.attribute('content').value).to eq('My Title')

        tag = doc.xpath("//meta[@name='citation_title']")
        expect(tag.attribute('content').value).to eq('My Title')

        expect(doc.xpath("//meta[@name='citation_author']")).to be_blank
        expect(doc.xpath("//meta[@name='citation_publication_date']")).to be_blank
        expect(doc.xpath("//meta[@name='citation_pdf_url']")).to be_blank
        expect(doc.xpath("//meta[@name='citation_dissertation_institution']")).to be_blank
      end
    end
  end
  describe 'content for twitter cards' do
    let(:content) { view.content_for(:twitter_meta) }
    let(:expected_twitter_meta_tags) do
      {
        'twitter:card' => 'product',
        'twitter:site' => '@SamveraRepo',
        'twitter:creator' => '@bot4lib',
        'twitter:data1' => 'bacon, sausage, eggs',
        'twitter:label1' => 'Keywords',
        'twitter:data2' => 'http://example.org/rs/1',
        'twitter:label2' => 'Rights Statement'
      }
    end

    let(:expected_og_meta_tags) do
      {
        'og:site_name' => I18n.t('hyrax.product_name'),
        'og:type' => 'object',
        'og:title' => 'My Title',
        'og:description' => 'Lorem ipsum lorem ipsum.',
        'og:image' => 'http://test.host/downloads/123',
        'og:url' => 'http://test.host/concern/generic_works/999'
      }
    end
    before do
      allow(presenter).to receive(:tweeter).and_return("@#{depositor.twitter_handle}")
      allow(controller).to receive(:current_user).and_return(depositor)
      allow(::User).to receive(:find_by_user_key).and_return(depositor.user_key)
      render partial: 'shared/citations', locals: { presenter: presenter }
    end

    it 'appears in meta tags' do
      twitter_meta_tags = Nokogiri::HTML(content).xpath("//meta[contains(@name, 'twitter:') or contains(@property, 'og:')]")
      expect(twitter_meta_tags.count).to eq(13)
    end

    it 'displays the spectrum of twitter meta attributes' do
      doc = Nokogiri::HTML(content)

      expected_twitter_meta_tags.each do |name, expected_value|
        tag = doc.xpath("//meta[@name='#{name}']")
        expect(tag.attribute('content').value).to eq(expected_value),
          "Expected meta tag '#{name}' to have content '#{expected_value}'"
      end

      expected_og_meta_tags.each do |property, expected_value|
        tag = doc.xpath("//meta[@property='#{property}']")
        expect(tag.attribute('content').value).to eq(expected_value),
          "Expected meta tag '#{property}' to have content '#{expected_value}'"
      end
    end
  end
end
