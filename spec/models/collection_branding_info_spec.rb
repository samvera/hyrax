RSpec.describe CollectionBrandingInfo, type: :model do
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

  describe "save banner and logo info" do
    it "saves the banner info, copy banner to public area, and remove it from temp area" do
      expect(FileUtils).to receive(:mkdir_p).with(banner_info.find_local_dir_name('123', 'banner')).and_return("/public/123/banner/")
      expect(FileUtils).to receive(:cp).with('/tmp/12/34/56', banner_info.find_local_dir_name('123', 'banner') + "/banner.gif")
      expect(FileUtils).to receive(:remove_file).with('/tmp/12/34/56')
      expect(File).to receive(:exist?).and_return(true)
      banner_info.save("/tmp/12/34/56")

      expect(banner_info.local_path).to eq(banner_info.find_local_dir_name('123', 'banner') + "/banner.gif")
      expect(banner_info.alt_text).to eq("banner alt txt")
      expect(banner_info.target_url).to eq("")
    end

    it "saves the logo info, copy logo to public area, and remove it from temp area" do
      expect(FileUtils).to receive(:mkdir_p).with(logo_info.find_local_dir_name('123', 'logo')).and_return("/public/123/logo/")
      expect(FileUtils).to receive(:cp).with('/tmp/12/34/56', logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
      expect(FileUtils).to receive(:remove_file).with('/tmp/12/34/56')
      expect(File).to receive(:exist?).and_return(true)
      logo_info.save("/tmp/12/34/56")

      expect(logo_info.local_path).to eq(logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
      expect(logo_info.alt_text).to eq("This is the logo")
      expect(logo_info.target_url).to eq("http://logo.com")
    end
  end

  describe "remove banner and log files from the public directroy" do
    it "removes banner file from public directory" do
      expect(FileUtils).to receive(:remove_file).with(banner_info.find_local_dir_name('123', 'banner') + "/banner.gif")
      expect(File).to receive(:exist?).and_return(true)
      banner_info.delete(banner_info.find_local_dir_name('123', 'banner') + "/banner.gif")
    end

    it "removes logo file from public directory" do
      expect(FileUtils).to receive(:remove_file).with(logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
      expect(File).to receive(:exist?).and_return(true)
      logo_info.delete(logo_info.find_local_dir_name('123', 'logo') + "/logo.gif")
    end
  end
end
