# frozen_string_literal: true
RSpec.describe CollectionBrandingInfo, type: :model do
  let(:storage_adapter) { Hyrax.config.branding_storage_adapter }

  let(:banner_info) do
    described_class.new(
      collection_id: "123",
      filename: "banner.gif",
      role: "banner",
      alt_txt: "banner alt txt",
      target_url: ""
    )
  end

  let(:logo_info) do
    described_class.new(
      collection_id: "123",
      filename: "logo.gif",
      role: "logo",
      alt_txt: "This is the logo",
      target_url: "http://logo.com"
    )
  end

  let(:file) { Tempfile.new('my_branding.jpg') }

  describe '#save' do
    it "saves the banner info, copy banner to public area, and remove it from temp area" do
      banner_info.save(file.path)

      expect(banner_info.local_path).to eq(banner_info.find_local_dir_name('123', 'banner') + "/banner.gif")
      expect(banner_info.alt_text).to eq("banner alt txt")
      expect(banner_info.target_url).to eq("")
    end

    it "saves the logo info, copy logo to public area, and remove it from temp area" do
      logo_info.save(file.path)

      expect(logo_info.local_path).to eq(logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
      expect(logo_info.alt_text).to eq("This is the logo")
      expect(logo_info.target_url).to eq("http://logo.com")
    end

    it "saves the logo info, but don't upload the log file" do
      expect(storage_adapter).not_to receive(:upload)

      logo_info.save(file.path, false)
      expect(logo_info.local_path).to eq(logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
      expect(logo_info.alt_text).to eq("This is the logo")
      expect(logo_info.target_url).to eq("http://logo.com")
    end
  end

  describe '#delete' do
    before { banner_info.save(file.path) }

    it "removes banner file" do
      expect { banner_info.delete }.to change {
        begin
          storage_adapter.find_by(id: banner_info.local_path)
        rescue Valkyrie::StorageAdapter::FileNotFound
          'Raised FileNotFound' # Convert the raised error so change can detect it
        end
      }.from(be_a(Valkyrie::StorageAdapter::File)).to(eq 'Raised FileNotFound')
    end
  end
end
