# frozen_string_literal: true
RSpec.describe Hyrax::AuthorityRenderingHelper do
  describe ".linkable_uri?" do
    it "is true for an absolute http URI" do
      expect(described_class.linkable_uri?("http://example.com")).to be true
    end

    it "is true for an absolute https URI" do
      expect(described_class.linkable_uri?("https://example.com/foo")).to be true
    end

    it "is case-insensitive on the scheme" do
      expect(described_class.linkable_uri?("HTTPS://example.com")).to be true
    end

    it "is false for a non-URI free-text value" do
      # `URI.parse("moomin")` does not raise; it returns a URI::Generic with
      # no scheme. The check must reject it.
      expect(described_class.linkable_uri?("moomin")).to be false
    end

    it "is false for a value with an unsafe scheme" do
      expect(described_class.linkable_uri?("javascript:alert(1)")).to be false
    end

    it "is false for a data: URL" do
      expect(described_class.linkable_uri?("data:text/html,<script>alert(1)</script>")).to be false
    end

    it "is false for an ftp URL" do
      expect(described_class.linkable_uri?("ftp://example.com")).to be false
    end

    it "is false for a protocol-relative URL" do
      expect(described_class.linkable_uri?("//example.com")).to be false
    end

    it "is false for a relative path" do
      expect(described_class.linkable_uri?("/relative/path")).to be false
    end

    it "is false for a string URI.parse refuses" do
      expect(described_class.linkable_uri?("text with spaces")).to be false
    end

    it "is false for a blank string" do
      expect(described_class.linkable_uri?("")).to be false
    end

    it "is false for nil" do
      expect(described_class.linkable_uri?(nil)).to be false
    end
  end
end
