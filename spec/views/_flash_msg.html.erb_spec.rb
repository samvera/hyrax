# frozen_string_literal: true
RSpec.describe '/_flash_msg.html.erb', type: :view do
  before do
    allow(view).to receive(:flash).and_return(flash)
  end

  let(:flash) { { notice: notice, error: error, alert: alert } }
  let(:i18n_html) { t('hyrax.works.create.after_create_html', application_name: 'Whatever') }

  context 'with a single flash notice' do
    let(:notice) { i18n_html }
    let(:error) { [] }
    let(:alert) { [] }

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
    let(:error) { [] }
    let(:alert) { [] }

    it 'renders the notice joined with unescaped line break' do
      render
      expect(rendered).not_to have_content '<br/>'
      expect(rendered).not_to have_content '</span>'
    end
  end

  context 'with a single flash error' do
    let(:notice) { [] }
    let(:error) { ['Error: something has gone wrong'] }
    let(:alert) { [] }

    it 'renders the correct errors' do
      render
      expect(rendered).to have_content('Error')
    end
  end

  context 'with a single flash alert' do
    let(:notice) { [] }
    let(:error) { [] }
    let(:alert) { ['Warning: something to be aware of'] }

    it 'renders the correct alert' do
      render
      expect(rendered).to have_content('Warning: something to be aware of')
    end
  end
end
