describe Sufia::Analytics do
  before do
    token = OAuth2::AccessToken.new(nil, nil)
    allow(subject).to receive(:token).and_return(token)
  end

  it 'responds to :config' do
    expect(subject).to respond_to(:config)
  end

  it 'reads its config from a yaml file' do
    expect(subject.config.keys.sort).to eql ['app_name', 'app_version', 'client_email', 'privkey_path', 'privkey_secret']
  end

  it 'responds to :user' do
    expect(subject).to respond_to(:user)
  end

  it 'instantiates a user' do
    expect(subject.user).to be_a(Legato::User)
  end

  it 'responds to :profile' do
    expect(subject).to respond_to(:profile)
  end
end
