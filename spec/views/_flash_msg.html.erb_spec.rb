# frozen_string_literal: true
RSpec.describe '/_flash_msg.html.erb', type: :view do
  before do
    allow(view).to receive(:flash).and_return(flash)
  end

  let(:flash) { { notice: notice } }
  let(:i18n_html) { t('hyrax.works.create.after_create_html', application_name: 'Whatever') }

  context 'with a single flash notice' do
    let(:notice) { i18n_html }

    it 'renders with HTML unescaped' do
      render
      expect(rendered).not_to have_content '</span>'
    end
  end

  context 'with multiple flash notices' do
    let(:notice) do
      [
        i18n_html,
        'Lorem ipsum!'
      ]
    end

    it 'renders the notice joined with unescaped line break' do
      render
      expect(rendered).not_to have_content '<br/>'
      expect(rendered).not_to have_content '</span>'
    end
  end
end
