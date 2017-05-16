require 'spec_helper'

RSpec.describe Hyrax::FixityChecksController do
  routes { Hyrax::Engine.routes }
  let(:user) { create(:user) }
  let(:file_set) { FileSet.create { |fs| fs.apply_depositor_metadata(user) } }
  let(:binary) { File.open(fixture_path + '/world.png') }
  let(:file) { Hydra::Derivatives::IoDecorator.new(binary, 'image/png', 'world.png') }

  before { Hydra::Works::UploadFileToFileSet.call(file_set, file) }

  context "when signed in" do
    describe "POST create" do
      before { sign_in user }

      it "returns json with the result" do
        post :create, params: { file_set_id: file_set }, xhr: true
        expect(response).to be_success
        json = JSON.parse(response.body)
        # json is a structure like this:
        #   { file_id => [{ "checked_uri" => "...4-4d71-83ba-1bc52a5e4300/fcr:versions/version1", "passed" => true },
        #                 { "checked_uri" => ".../version2", "passed" => false },
        #                 ...] }
        json.each do |file_id, array_of_checks|
          array_of_checks.each do |check_hash|
            ["file_set_id", "file_id", "checked_uri", "passed",
             "expected_result", "created_at"].each do |internal_key|
              expect(check_hash).to have_key(internal_key)
            end
            expect(check_hash["passed"]).to be_in([true, false])
          end
        end
        fixity_results = json.values.flatten.collect { |result| result["passed"] }
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
