# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_redirects.html.erb', type: :view do
  let(:form_object_name) { 'generic_work' }
  let(:form) { double('form', object_name: form_object_name, object: form_object) }
  let(:form_object) { double('resource', redirects: redirects) }
  let(:redirects) { [] }

  before do
    allow(view).to receive(:redirects_tab?).and_return(true)
    allow(view).to receive(:request).and_return(double(base_url: 'http://example.test'))
  end

  let(:page) do
    render partial: 'hyrax/base/form_redirects', locals: { f: form }
    Capybara::Node::Simple.new(rendered)
  end

  def radio_for_index(value)
    page.find("input[type=radio][name='#{form_object_name}[redirects_display_url_index]'][value='#{value}']")
  end

  context 'when the resource has no redirects' do
    let(:redirects) { [] }

    it 'renders the "None" radio as the only checked option' do
      expect(radio_for_index('')).to be_checked
    end

    it 'renders no row radios' do
      expect(page).not_to have_css("input[type=radio][name='#{form_object_name}[redirects_display_url_index]'][value='0']")
    end

    it 'renders the Add another alias button' do
      expect(page).to have_button('Add another alias')
    end

    it 'renders a row template element' do
      expect(page).to have_css('template[data-redirects-row-template]', visible: :all)
    end
  end

  context 'when the resource has one redirect with display_url false' do
    let(:redirects) { [Hyrax::Redirect.new(path: '/handle/1', display_url: false)] }

    it 'checks the "None" radio and leaves per-row radios unchecked' do
      expect(radio_for_index('')).to be_checked
      expect(radio_for_index('0')).not_to be_checked
    end
  end

  context 'when one entry is flagged as display_url' do
    let(:redirects) do
      [
        Hyrax::Redirect.new(path: '/handle/1', display_url: false),
        Hyrax::Redirect.new(path: '/handle/2', display_url: true)
      ]
    end

    it 'checks only the matching row radio' do
      expect(radio_for_index('')).not_to be_checked
      expect(radio_for_index('0')).not_to be_checked
      expect(radio_for_index('1')).to be_checked
    end

    it 'shares one radio group name across all rows' do
      group_radios = page.all("input[type=radio][name='#{form_object_name}[redirects_display_url_index]']")
      # None radio + 2 row radios (template content isn't in the live DOM)
      expect(group_radios.size).to eq(3)
    end
  end

  context 'when redirects holds plain hashes (re-render after validation failure)' do
    let(:redirects) do
      [
        { 'path' => '/handle/1', 'display_url' => true }
      ]
    end

    it 'still wraps and renders the display_url radio as checked' do
      expect(radio_for_index('0')).to be_checked
    end
  end
end
