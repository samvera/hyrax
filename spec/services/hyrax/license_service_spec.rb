RSpec.describe Hyrax::LicenseService do
  before do
    # Configure QA to use fixtures
    qa_fixtures = { local_path: File.expand_path('spec/fixtures/authorities') }
    allow(Qa::Authorities::Local).to receive(:config).and_return(qa_fixtures)
  end
  let(:service) { described_class.new }

  describe "#select_active_options" do
    it "returns active terms" do
      expect(service.select_active_options).to include(["First Active Term", "demo_id_01"], ["Second Active Term", "demo_id_02"])
    end

    it "does not return inactive terms" do
      expect(service.select_active_options).not_to include(["Third is an Inactive Term", "demo_id_03"], ["Fourth is an Inactive Term", "demo_id_04"])
    end
  end

  describe "#select_all_options" do
    it "returns both active and inactive terms" do
      expect(service.select_all_options).to include(["Fourth is an Inactive Term", "demo_id_04"], ["First Active Term", "demo_id_01"])
    end
  end

  describe "#label" do
    it "resolves for ids of active terms" do
      expect(service.label('demo_id_01')).to eq("First Active Term")
    end

    it "resolves for ids of inactive terms" do
      expect(service.label('demo_id_03')).to eq("Third is an Inactive Term")
    end
  end
end
