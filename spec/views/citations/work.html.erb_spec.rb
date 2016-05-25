
describe 'citations/work.html.erb', type: :view do
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Gandalf Grey'] }
  let(:creator)     { ['Bilbo Baggins', 'Baggins, Frodo'] }
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/'],
      title_tesim: ['the Roared about the Langs'],
      based_near_tesim: ['London'],
      date_created_tesim: ['1969']
    )
  }
  let(:ability) { nil }
  let(:presenter) do
    Sufia::WorkShowPresenter.new(solr_document, ability)
  end

  describe 'citations' do
    let(:page) { Capybara::Node::Simple.new(rendered) }
    let(:citation) { page.find(citation_selector) }
    let(:title_selector) { "#{citation_selector} > i.citation-title" }
    let(:author_selector) { "#{citation_selector} > .citation-author" }
    before do
      assign(:presenter, presenter)
      render
    end

    context 'in APA style' do
      let(:citation_selector) { 'span.apa-citation' }
      let(:formatted_title) { 'the Roared about the Langs.' }
      # entities will be unescaped
      let(:authors) { 'Baggins, B., & Baggins, F.' }
      it 'exports title' do
        expect(page).to have_selector(title_selector, count: 1)
        expect(page.find(title_selector)).to have_content(formatted_title)
      end
      it 'exports authors' do
        expect(page).to have_selector(author_selector, count: 1)
        expect(page.find(author_selector)).to have_content(authors)
      end
      it 'cites' do
        expect(citation.text).to eql("#{authors} (1969). #{formatted_title} London.")
      end
    end
    context 'in Chicago style' do
      let(:citation_selector) { 'span.chicago-citation' }
      let(:formatted_title) { 'The Roared about the Langs.' }
      let(:authors) { 'Baggins, Bilbo, and Frodo Baggins.' }
      it 'exports title' do
        expect(page).to have_selector(title_selector, count: 1)
        expect(page.find(title_selector)).to have_content(formatted_title)
      end
      it 'exports authors' do
        expect(page).to have_selector(author_selector, count: 1)
        expect(page.find(author_selector)).to have_content(authors)
      end
      it 'cites' do
        expect(citation.text).to eql("#{authors} 1969. #{formatted_title} London.")
      end
    end
    context 'in MLA style' do
      let(:citation_selector) { 'span.mla-citation' }
      let(:formatted_title) { 'the Roared About the Langs.' }
      let(:authors) { 'Baggins, Bilbo, and Frodo Baggins.' }
      it 'exports title' do
        expect(page).to have_selector(title_selector, count: 1)
        expect(page.find(title_selector)).to have_content(formatted_title)
      end
      it 'exports authors' do
        expect(page).to have_selector(author_selector, count: 1)
        expect(page.find(author_selector)).to have_content(authors)
      end
      it 'cites' do
        expect(citation.text).to eql("#{authors} #{formatted_title} London, 1969.")
      end
    end
  end
end
