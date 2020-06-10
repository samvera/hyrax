# frozen_string_literal: true
RSpec.describe "hyrax/homepage/index.html.erb", type: :view do
  let(:groups) { [] }
  let(:ability) { instance_double("Ability", can?: false) }
  let(:presenter) do
    instance_double(Hyrax::HomepagePresenter,
                    create_work_presenter: type_presenter,
                    create_many_work_types?: true,
                    draw_select_work_modal?: true)
  end
  let(:type_presenter) { instance_double(Hyrax::SelectTypeListPresenter) }

  before do
    allow(view).to receive(:signed_in?).and_return(signed_in)
    allow(controller).to receive(:current_ability).and_return(ability)
    assign(:presenter, presenter)
    stub_template 'shared/_select_work_type_modal.html.erb' => 'modal'
    stub_template "hyrax/homepage/_marketing.html.erb" => "marketing"
    stub_template "hyrax/homepage/_home_content.html.erb" => "home content"
  end

  describe 'meta tag with current user info' do
    let(:realtime_notifications) { true }

    before do
      allow(Hyrax.config).to receive(:realtime_notifications?).and_return(realtime_notifications)
      allow(view).to receive(:on_the_dashboard?).and_return(false)
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(presenter).to receive(:display_share_button?).and_return(true)
      stub_template "_controls.html.erb" => "controls"
      stub_template "_masthead.html.erb" => "masthead"
      render template: 'hyrax/homepage/index', layout: 'layouts/homepage'
    end

    context 'when signed in' do
      let(:signed_in) { true }
      let(:current_user) { create(:user) }

      it 'renders' do
        expect(rendered).to have_selector('meta[name="current-user"]', visible: false)
      end

      context 'when realtime notifications are disabled' do
        let(:realtime_notifications) { false }

        it 'does not render' do
          expect(rendered).not_to have_selector('meta[name="current-user"]', visible: false)
        end
      end
    end

    context 'when not signed in' do
      let(:signed_in) { false }
      let(:current_user) { nil }

      it 'does not render' do
        expect(rendered).not_to have_selector('meta[name="current-user"]', visible: false)
      end
    end
  end

  describe "share your work button" do
    before do
      allow(presenter).to receive(:display_share_button?).and_return(display_share_button)
      render
    end

    context "when not signed in" do
      let(:signed_in) { false }

      context "when the button always displays" do
        let(:display_share_button) { true }

        it "displays" do
          expect(rendered).to have_content t("hyrax.share_button")
        end

        it 'links to the my works path' do
          expect(rendered).to have_selector('a[href="/dashboard/my/works"]')
        end
      end
      context "when the button displays for users with rights" do
        let(:display_share_button) { false }

        it "does not display" do
          expect(rendered).not_to have_content t("hyrax.share_button")
        end
      end
    end

    context "when signed in" do
      let(:signed_in) { true }

      context "when the button always displays" do
        let(:display_share_button) { true }

        context "and there are multiple work types" do
          it "displays a button that pops up the modal" do
            expect(rendered).to have_selector('a[data-behavior="select-work"][href="#"]',
                                              text: t("hyrax.share_button"))
          end
        end

        context "and there is a single work type" do
          let(:presenter) do
            instance_double(Hyrax::HomepagePresenter,
                            create_work_presenter: type_presenter,
                            create_many_work_types?: false,
                            draw_select_work_modal?: true,
                            first_work_type: GenericWork)
          end

          it "displays a link to create that work type" do
            expect(rendered).to have_selector('a:not([data-behavior])[href="/concern/generic_works/new"]',
                                              text: t("hyrax.share_button"))
          end
        end
      end

      context "when the button displays for users with rights" do
        let(:display_share_button) { false }

        it "does not display" do
          expect(rendered).not_to have_content t("hyrax.share_button")
        end
      end
    end
  end
end
