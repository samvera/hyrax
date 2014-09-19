require 'spec_helper'

describe DepositorsController do
  let (:user) { FactoryGirl.find_or_create(:jill) }
  let (:grantee) { FactoryGirl.find_or_create(:archivist) }

  describe "as a logged in user" do
    before do
      sign_in user
    end

    describe "create" do
      it "should be successful" do
        expect { post :create, user_id: user.user_key, grantee_id: grantee.user_key, format: 'json' }.to change{ ProxyDepositRights.count }.by(1)
        expect(response).to be_success
      end

      it "should not add current user" do
        expect { post :create, user_id: user.user_key, grantee_id: user.user_key, format: 'json' }.to change{ ProxyDepositRights.count }.by(0)
        expect(response).to be_success
        expect(response.body).to be_blank
      end
    end

    describe "destroy" do
      before do
        user.can_receive_deposits_from << grantee
      end
      it "should be successful" do
        expect { delete :destroy, user_id: user.user_key, id: grantee.user_key, format: 'json' }.to change{ ProxyDepositRights.count }.by(-1)
      end
    end
  end

  describe "as a user without access" do
    before do
      sign_in FactoryGirl.create(:curator)
    end
    describe "create" do
      it "should not be successful" do
        expect { post :create, user_id: user, grantee_id: grantee, format: 'json' }.to raise_error
      end
    end
    describe "destroy" do
      it "should not be successful" do
        expect { delete :destroy, user_id: user, id: grantee, format: 'json' }.to raise_error
      end
    end
  end
end
