describe 'users/_following_modal.html.erb', type: :view do
  before do
    allow(controller).to receive(:current_user) { current_user }
    render partial: 'users/following_modal', locals: { user: view_user, following: following }
  end

  let(:frank) { FactoryGirl.create(:user, display_name: "Frank") }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  context 'when following users' do
    let(:following) { [frank] }
    let(:current_user) { frank }
    let(:view_user) {}
    it "draws user list" do
      expect(page).to have_link("Frank", href: "/users/#{frank.to_param}")
    end
  end

  context "when not following users" do
    let(:following) { [] }

    context 'when logged in' do
      let(:current_user) { frank }

      before do
        assign :user, frank
      end

      context 'when current user is not following anyone' do
        let(:view_user) { frank }

        it "indicates that you are not following anyone" do
          expect(page).to have_text "You are not following anyone."
        end
      end

      context 'when another user is not following anyone' do
        let(:view_user) { stub_model(User) }

        it "indicates that the user is not following anyone" do
          expect(page).to have_text "This user is not following anyone."
        end
      end
    end

    context "when not logged in" do
      let(:current_user) {}
      let(:view_user) { frank }

      it "indicates the user is not following anyone" do
        expect(page).to have_text "This user is not following anyone."
      end
    end
  end
end
