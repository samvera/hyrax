
describe CurationConcerns::AuditsController do
  routes { Sufia::Engine.routes }
  let(:user) { create(:user) }
  let(:file_set) { FileSet.create { |fs| fs.apply_depositor_metadata(user) } }
  let(:binary) { File.open(fixture_path + '/world.png') }
  let(:file) { Hydra::Derivatives::IoDecorator.new(binary, 'image/png', 'world.png') }
  before { Hydra::Works::UploadFileToFileSet.call(file_set, file) }

  context "when signed in" do
    describe "POST create" do
      before { sign_in user }

      it "returns json with the result" do
        xhr :post, :create, file_set_id: file_set
        expect(response).to be_success
        json = JSON.parse(response.body)
        # json is a structure like this:
        #   { file_id => [{ "version" => "version1", "pass" => 999 },
        #                 { "version" => "version2", "pass" => 0 },
        #                 ...] }
        audit_results = json.values.flatten.collect { |result| result["pass"] }
        expect(audit_results.reduce(true) { |sum, value| sum && value }).to eq 999 # never been audited
      end
    end
  end

  context "when not signed in" do
    describe "POST create" do
      it "returns json with the result" do
        xhr :post, :create, file_set_id: file_set
        expect(response.code).to eq '401'
      end
    end
  end
end
