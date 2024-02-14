# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_progress.html.erb', type: :view do
  let(:ability) { double }
  let(:user) { stub_model(User) }
  let(:form) do
    Hyrax.config.disable_wings ? Hyrax::Forms::ResourceForm.for(resource: work).prepopulate! : Hyrax::GenericWorkForm.new(work, ability, controller)
  end
  let(:page) do
    view.simple_form_for form do |f|
      render 'hyrax/base/form_progress', f: f
    end
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    # Stub visibility, or it will hit fedora
    allow(work).to receive(:visibility).and_return('open')
  end

  context "for a new object" do
    before { assign(:form, form) }

    let(:work) { GenericWork.new }

    context "with options for proxy" do
      let(:proxies) { [stub_model(User, email: 'bob@example.com')] }

      before do
        allow(Flipflop).to receive(:proxy_deposit?).and_return(true)
        allow(user).to receive(:can_make_deposits_for).and_return(proxies)
      end

      it "shows options for proxy" do
        expect(page).to have_content 'Proxy Depositors - Select the user on whose behalf you are depositing'
        expect(page).to have_selector("select#generic_work_on_behalf_of option[value=\"\"]", text: 'Yourself')
        expect(page).to have_selector("select#generic_work_on_behalf_of option[value=\"bob@example.com\"]")
      end

      context 'when feature disabled' do
        before do
          allow(Flipflop).to receive(:proxy_deposit?).and_return(false)
        end

        it "does not show options for proxy" do
          expect(page).not_to have_content 'Proxy Depositors - Select the user on whose behalf you are depositing'
          expect(page).not_to have_selector("select#generic_work_on_behalf_of option[value=\"\"]", text: 'Yourself')
          expect(page).not_to have_selector("select#generic_work_on_behalf_of option[value=\"bob@example.com\"]")
        end
      end
    end

    context "without options for proxy" do
      let(:proxies) { [] }

      before do
        allow(user).to receive(:can_make_deposits_for).and_return(proxies)
      end
      it "doesn't show options for proxy" do
        expect(page).not_to have_content 'Proxy Depositors - Select the user on whose behalf you are depositing'
        expect(page).not_to have_selector 'select#generic_work_on_behalf_of'
      end
    end

    context "with active deposit agreement" do
      before do
        allow(Flipflop).to receive(:active_deposit_agreement_acceptance?)
          .and_return(true)
      end
      it "shows accept text" do
        expect(page).to have_content 'Check deposit agreement'
        expect(page).to have_content 'I have read and agree to the'
        expect(page).to have_link 'Deposit Agreement', href: '/agreement'
        expect(page).not_to have_selector("#agreement[checked]")
      end
    end

    context "with passive deposit agreement" do
      before do
        allow(Flipflop).to receive(:active_deposit_agreement_acceptance?)
          .and_return(false)
      end
      it "shows accept text" do
        expect(page).not_to have_content 'Check deposit agreement'
        expect(page).to have_content 'By saving this work I agree to the'
        expect(page).to have_link 'Deposit Agreement', href: '/agreement'
      end
    end

    context "with no deposit agreement" do
      before do
        allow(Flipflop).to receive(:show_deposit_agreement?).and_return(false)
      end
      it "does not display active accept text" do
        expect(page).not_to have_content 'I have read and agree to the'
        expect(page).not_to have_selector("#agreement[checked]")
      end
      it "does not display passive accept text" do
        expect(page).not_to have_content 'By saving this work I agree to the'
        expect(page).not_to have_link 'Deposit Agreement', href: '/agreement'
      end
    end

    context "with active deposit acceptance but no show deposit agreement" do
      before do
        allow(Flipflop).to receive(:show_deposit_agreement?).and_return(false)
        allow(Flipflop).to receive(:active_deposit_agreement_acceptance?)
          .and_return(true)
      end
      it "does not display the deposit agreement in the requirements" do
        expect(page).not_to have_selector("#required-agreement")
      end
    end
  end

  context "when the work has been saved before" do
    before do
      # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
      allow(work).to receive_messages(new_record?: false, new_record: false)
      assign(:form, form)
      allow(Hyrax.config).to receive(:active_deposit_agreement_acceptance)
        .and_return(true)
    end

    let(:work) { stub_model(GenericWork, id: '456', etag: '123456') }

    it "renders the deposit agreement already checked" do
      expect(page).to have_selector("#agreement[checked]")
    end

    # Not applicable without wings; see Hyrax::Forms::ResourceForm::LockKeyPrepopulator
    it 'renders the version', :active_fedora do
      expect(page).to have_selector("input#generic_work_version[value=\"123456\"]", visible: false)
    end
  end

  context 'when additional sections are added' do
    let(:work) { stub_model(GenericWork, id: '456', etag: '123456') }

    before do
      allow(work).to receive(:new_record?).and_return(false)
      assign(:form, form)
      allow(Hyrax.config).to receive(:active_deposit_agreement_acceptance)
        .and_return(true)

      allow(view).to receive(:form_progress_sections_for).with(form: form).and_return(['newsection'])
      stub_template 'hyrax/base/_form_progress_newsection.html.erb' => '<div class="list-group-item">New Section</div>'
    end

    it 'renders the additional sections' do
      expect(page).to have_text('New Section')
    end
  end
end
