describe Sufia::Analytics do
  before do
    token = OAuth2::AccessToken.new(nil, nil)
    allow(subject).to receive(:token).and_return(token)
  end

  describe "configuration" do
    context "When the yaml file has values" do
      it 'reads its config from a yaml file' do
        expect(subject.send(:config).keys.sort).to eql ['app_name', 'app_version', 'client_email', 'privkey_path', 'privkey_secret']
      end
    end

    context "When the yaml file has no values" do
      before do
        described_class.send(:remove_instance_variable, :@config)
        allow(File).to receive(:read).and_return("# Just comments\n# and comments\n")
      end
      it 'returns nil' do
        expect(Rails.logger).to receive(:error)
          .with(starting_with("Unable to fetch any keys from"))
        expect(subject.send(:config)).to be nil
      end
    end
  end

  it 'instantiates a user' do
    expect(subject.send(:user)).to be_a(Legato::User)
  end

  it 'responds to :profile' do
    expect(subject).to respond_to(:profile)
  end
end
