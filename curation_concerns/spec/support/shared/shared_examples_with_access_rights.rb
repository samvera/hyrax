shared_examples 'with_access_rights' do
  def prepare_subject_for_access_rights_visibility_test!
    # I am doing this because the actual persistence of the objects requires
    # so much more and I don't know for certain if it has happened.
    allow(subject).to receive(:persisted?).and_return(true)
  end

  it 'has an under_embargo?' do
    expect do
      subject.under_embargo?
    end.to_not raise_error
  end

  it 'has a visibility attribute' do
    expect(subject).to respond_to(:visibility)
    expect(subject).to respond_to(:visibility=)
  end

  describe 'open access' do
    it 'has an open_access?' do
      expect do
        subject.open_access?
      end.to_not raise_error
    end

    it 'sets visibility' do
      prepare_subject_for_access_rights_visibility_test!
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(subject).to be_open_access
    end
  end

  describe 'authenticated access' do
    it 'sets visibility' do
      prepare_subject_for_access_rights_visibility_test!
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(subject).to be_authenticated_only_access
    end

    it 'has an authenticated_only_access?' do
      expect do
        subject.authenticated_only_access?
      end.to_not raise_error
    end
  end

  describe 'private access' do
    it 'sets visibility' do
      prepare_subject_for_access_rights_visibility_test!
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(subject).to be_private_access
    end

    it 'has an private_access?' do
      expect do
        subject.private_access?
      end.to_not raise_error
    end
  end
end
