RSpec.describe Hyrax::SingleUseLinkPresenter do
  subject { described_class.new(link) }

  context "with any kind of link" do
    let(:link) { create(:download_link) }

    describe "#human_readable_expiration" do
      context "in more than one hour" do
        its(:human_readable_expiration) { is_expected.to eq("in 23 hours") }
      end
      context "in less than an hour" do
        before { allow(link).to receive(:expires).and_return(Time.zone.now) }
        its(:human_readable_expiration) { is_expected.to eq("in less than one hour") }
      end
    end

    describe "#short_key" do
      its(:short_key) { is_expected.to eq(link.download_key.first(6)) }
    end

    describe "delegated methods" do
      its(:download_key) { is_expected.to eq(link.download_key) }
      its(:expired?)    { is_expected.to eq(link.expired?) }
      its(:to_param)    { is_expected.to eq(link.to_param) }
    end
  end

  context "with a download link" do
    let(:link)        { create(:download_link) }

    its(:link_type)   { is_expected.to eq("Download") }
    its(:url_helper)  { is_expected.to eq("download_single_use_link_url") }
  end

  context "with a show link" do
    let(:link)        { create(:show_link) }

    its(:link_type)   { is_expected.to eq("Show") }
    its(:url_helper)  { is_expected.to eq("show_single_use_link_url") }
  end
end
