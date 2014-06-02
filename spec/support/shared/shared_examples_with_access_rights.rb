shared_examples 'with_access_rights' do

  def prepare_subject_for_access_rights_visibility_test!
    # I am doing this because the actual persistence of the objects requires
    # so much more and I don't know for certain if it has happened.
    allow(subject).to receive(:persisted?).and_return(true)
  end

  it "has an under_embargo?" do
    expect {
      subject.under_embargo?
    }.to_not raise_error
  end

  it "has a visibility attribute" do
    expect(subject).to respond_to(:visibility)
    expect(subject).to respond_to(:visibility=)
  end

  describe 'open access' do
    it "has an open_access?" do
      expect {
        subject.open_access?
      }.to_not raise_error
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

    it "has an authenticated_only_access?" do
      expect {
        subject.authenticated_only_access?
      }.to_not raise_error
    end
  end

  describe 'private access' do
    it 'sets visibility' do
      prepare_subject_for_access_rights_visibility_test!
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(subject).to be_private_access
    end


    it "has an private_access?" do
      expect {
        subject.private_access?
      }.to_not raise_error
    end
  end

  describe 'open_access_with_embargo_release_date' do
    it 'sets visibility' do
      if subject.respond_to?(:embargo_release_date=)
        prepare_subject_for_access_rights_visibility_test!
        subject.embargo_release_date = 2.days.from_now
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        expect(subject).to be_open_access_with_embargo_release_date
      end
    end

    it 'removes embargo release date when non embargo is set' do
      if subject.respond_to?(:embargo_release_date=)
        prepare_subject_for_access_rights_visibility_test!
        subject.embargo_release_date = 2.days.from_now
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        expect(subject.embargo_release_date).to be_nil
      end
    end

    it "has an open_access_with_embargo_release_date?" do
      expect {
        subject.open_access_with_embargo_release_date?
      }.to_not raise_error
    end
  end

end
