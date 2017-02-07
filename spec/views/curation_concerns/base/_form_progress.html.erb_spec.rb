require 'spec_helper'

describe 'curation_concerns/base/_form_progress.html.erb', type: :view do
  let(:ability) { double }
  let(:user) { stub_model(User) }
  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end

  before do
    view.lookup_context.view_paths.push 'app/views/curation_concerns'
    allow(controller).to receive(:current_user).and_return(user)
  end

  let(:page) do
    view.simple_form_for form do |f|
      render 'curation_concerns/base/form_progress', f: f
    end
    Capybara::Node::Simple.new(rendered)
  end

  context "for a new object" do
    before { assign(:form, form) }

    let(:work) { GenericWork.new }

    context "with options for proxy" do
      let(:proxies) { [stub_model(User, email: 'bob@example.com')] }
      before do
        allow(user).to receive(:can_make_deposits_for).and_return(proxies)
      end
      it "shows options for proxy" do
        expect(page).to have_content 'On behalf of'
        expect(page).to have_selector("select#generic_work_on_behalf_of option[value=\"\"]", text: 'Yourself')
        expect(page).to have_selector("select#generic_work_on_behalf_of option[value=\"bob@example.com\"]")
      end
    end

    context "without options for proxy" do
      let(:proxies) { [] }
      before do
        allow(user).to receive(:can_make_deposits_for).and_return(proxies)
      end
      it "doesn't show options for proxy" do
        expect(page).not_to have_content 'On behalf of'
        expect(page).not_to have_selector 'select#generic_work_on_behalf_of'
      end
    end

    context "with active deposit agreement" do
      it "shows accept text" do
        expect(page).to have_content 'I have read and agree to the'
        expect(page).to have_link 'Deposit Agreement', href: '/agreement'
        expect(page).not_to have_selector("#agreement[checked]")
      end
    end

    context "with passive deposit agreement" do
      before do
        allow(Sufia.config).to receive(:active_deposit_agreement_acceptance)
          .and_return(false)
      end
      it "shows accept text" do
        expect(page).to have_content 'By saving this work I agree to the'
        expect(page).to have_link 'Deposit Agreement', href: '/agreement'
      end
    end
  end

  context "when the work has been saved before" do
    before do
      allow(work).to receive(:new_record?).and_return(false)
      assign(:form, form)
    end

    let(:work) { stub_model(GenericWork, id: '456', etag: '123456') }

    it "renders the deposit agreement already checked and version" do
      expect(page).to have_selector("#agreement[checked]")
      expect(page).to have_selector("input#generic_work_version[value=\"123456\"]", visible: false)
    end
  end
end
