# frozen_string_literal: true
RSpec.describe Hyrax::FixityChecksController do
  routes { Hyrax::Engine.routes }
  let(:user) { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :with_files, depositor: user.user_key) }
  context "when signed in" do
    describe "POST create" do
      before { sign_in user }

      let(:json_response) { JSON.parse(response.body) }

      it "returns json with the result" do
        pending 'Needs Valkyrie fixity support' if Hyrax.config.disable_wings
        post :create, params: { file_set_id: file_set }, xhr: true

        expect(response).to be_successful
        # json is a structure like this:
        #   { file_id => [{ "checked_uri" => "...4-4d71-83ba-1bc52a5e4300/fcr:versions/version1", "passed" => true },
        #                 { "checked_uri" => ".../version2", "passed" => false },
        #                 ...] }
        json_response.each_value do |array_of_checks|
          array_of_checks.each do |check_hash|
            expect(check_hash.keys).to include("file_set_id", "file_id", "checked_uri", "passed", "expected_result", "created_at")
            expect(check_hash["passed"]).to be_in([true, false])
          end
        end
        fixity_results = json_response.values.flatten.collect { |result| result["passed"] }
        expect(fixity_results.all? { |r| r == true }).to be true
      end
    end
  end

  context "when not signed in" do
    describe "POST create" do
      it "returns json with the result" do
        post :create, params: { file_set_id: file_set }, xhr: true

        expect(response.code).to eq '401'
      end
    end
  end
end
