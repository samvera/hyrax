# frozen_string_literal: true
RSpec.describe Hyrax::Admin::StrategiesController do
  describe "#update" do
    before do
      # Added when Flipflop bumped to 2.3.2. See also https://github.com/voormedia/flipflop/issues/26
      Flipflop::FeatureSet.current.instance_variable_set(:@features, original_feature_hash.merge(feature_id => feature))

      sign_in user
    end

    after do
      Flipflop::FeatureSet.current.instance_variable_set(:@features, original_feature_hash)
    end

    let(:original_feature_hash) { Flipflop::FeatureSet.current.instance_variable_get(:@features) }
    let(:user) { create(:user) }
    let(:strategy) { Flipflop::Strategies::ActiveRecordStrategy.new(class: Hyrax::Feature).key }
    let(:feature) { double('feature', id: feature_id, key: 'foo') }
    let(:feature_id) { :my_feature }

    context "when not authorized" do
      it "redirects away" do
        patch :update, params: { feature_id: feature.id, id: strategy }
        expect(response).to redirect_to root_path
      end
    end

    context "when authorized" do
      before do
        allow(controller).to receive_messages(current_user: user)
        expect(user).to receive(:groups).and_return(['admin', 'registered'])
      end

      it "is successful" do
        patch :update, params: { feature_id: feature.id, id: strategy }

        expect(response.location)
          .to include Hyrax::Engine.routes.url_helpers.admin_features_path(locale: 'en')
      end
    end
  end
end
