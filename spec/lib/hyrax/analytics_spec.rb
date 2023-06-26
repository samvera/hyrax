# frozen_string_literal: true
RSpec.describe Hyrax::Analytics do
  before do
    ENV['GOOGLE_ANALYTICS_ID'] = 'UA-XXXXXXXX'
    ENV['GOOGLE_OAUTH_APP_NAME'] = 'My App Name'
    ENV['GOOGLE_OAUTH_APP_VERSION'] = '0.0.1'
    ENV['GOOGLE_OAUTH_PRIVATE_KEY_PATH'] = '/tmp/privkey.p12'
    ENV['GOOGLE_OAUTH_PRIVATE_KEY_VALUE'] = ''
    ENV['GOOGLE_OAUTH_PRIVATE_KEY_SECRET'] = 's00pers3kr1t'
    ENV['GOOGLE_OAUTH_CLIENT_EMAIL'] = 'oauth@example.org'

    described_class.send(:remove_instance_variable, :@config) if described_class.send(:instance_variable_defined?, :@config)
  end

  describe "configuration" do
    let(:config) { described_class.send(:config) }

    context "When the yaml file has values" do
      it "is valid" do
        expect(config).to be_valid
      end

      it 'reads its config from a yaml file' do
        expect(config.analytics_id).to eql 'UA-XXXXXXXX'
        expect(config.app_name).to eql 'My App Name'
        expect(config.app_version).to eql '0.0.1'
        expect(config.privkey_value).to be_nil
        expect(config.privkey_path).to eql '/tmp/privkey.p12'
        expect(config.privkey_secret).to eql 's00pers3kr1t'
        expect(config.client_email).to eql 'oauth@example.org'
      end
    end

    context "When the yaml file has a deprecated format" do
      before do
        allow(File).to receive(:read).and_return <<-FILE
          analytics:
            app_name: My App Name
            app_version: 0.0.1
            privkey_value:
            privkey_path: /tmp/privkey.p12
            privkey_secret: s00pers3kr1t
            client_email: oauth@example.org
        FILE
      end

      it 'reads its config from a yaml file' do
        expect(config.app_name).to eql 'My App Name'
        expect(config.app_version).to eql '0.0.1'
        expect(config.privkey_value).to be_nil
        expect(config.privkey_path).to eql '/tmp/privkey.p12'
        expect(config.privkey_secret).to eql 's00pers3kr1t'
        expect(config.client_email).to eql 'oauth@example.org'
      end
    end

    context "When the yaml file has no values" do
      before do
        allow(File).to receive(:read).and_return("# Just comments\n# and comments\n")
      end

      it "is not valid" do
        expect(Hyrax.logger).to receive(:error)
          .with(starting_with("Unable to fetch any keys from"))
        expect(config).not_to be_valid
      end
    end
  end

  describe "#user" do
    before do
      token = OAuth2::AccessToken.new(nil, nil)
      allow(subject).to receive(:token).and_return(token)
    end
    it 'instantiates a user' do
      expect(subject.send(:user)).to be_a(Legato::User)
    end
  end

  describe "#profile" do
    subject { described_class.profile }

    context "when the private key file and private key value are missing" do
      it "raises an error" do
        expect { subject }.to raise_error RuntimeError, "Private key file for Google analytics was expected at '/tmp/privkey.p12', but no file was found."
      end
    end

    context "when the config is not valid" do
      before do
        allow(File).to receive(:read).and_return("# Just comments\n# and comments\n")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
