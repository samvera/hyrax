require 'spec_helper'

describe BlacklightHelper do
  describe "document_partial_name" do
    let(:field_name) { 'has_model_s' }

    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.show.display_type_field = field_name
      end
    end

    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
    end

    it "should lop off everything before the first colin after the slash" do
      expect(helper.document_partial_name('has_model_s' => ["info:fedora/afmodel:Presentation"])).to eq "presentation"
      expect(helper.document_partial_name('has_model_s' => ["info:fedora/hull-cModel:genericContent"])).to eq "generic_content"
    end

    context "with a single valued field" do
      let(:field_name) { 'active_fedora_model_ssi' }
      it "should support single valued fields" do
        expect(helper.document_partial_name('active_fedora_model_ssi' => "Chicken")).to eq "chicken"
      end
    end

    it "should handle periods" do
      expect(helper.document_partial_name('has_model_s' => ["info:fedora/afmodel:text.PDF"])).to eq "text_pdf"
    end
  end
end
