require 'spec_helper'

describe CurationConcerns::PermissionBadge do
  let(:badge) { described_class.new(solr_doc) }
  let(:solr_doc) { SolrDocument.new(attributes) }
  let(:attributes) { {} }

  describe "#render" do
    subject { badge.render }
    context "when open-access with embargo" do
      let(:attributes) { { read_access_group_ssim: ['public'], embargo_release_date_dtsi: '2016-05-04' } }
      it { is_expected.to eq "<span title=\"Open Access with Embargo\" class=\"label label-warning\">Open Access with Embargo</span>" }
    end

    context "when open-access" do
      let(:attributes) { { read_access_group_ssim: ['public'] } }
      it { is_expected.to eq "<span title=\"Open Access\" class=\"label label-success\">Open Access</span>" }
    end

    context "when registered" do
      let(:attributes) { { read_access_group_ssim: ['registered'] } }
      it { is_expected.to eq "<span title=\"Institution Name\" class=\"label label-info\">Institution Name</span>" }
    end

    context "when private" do
      it { is_expected.to eq "<span title=\"Private\" class=\"label label-danger\">Private</span>" }
    end
  end
end
