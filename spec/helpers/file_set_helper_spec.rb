describe FileSetHelper, type: :helper do
  describe '#display_multiple' do
    subject { helper.display_multiple(['Title with < 50Hz frequency. http://www.example.com. & More text', 'Other title']) }
    it "escapes input" do
      expect(subject).to start_with('Title with &lt; 50Hz frequency. ')
      expect(subject).to end_with('. &amp; More text | Other title')
    end
    it "adds links" do
      expect(subject).to include('<a href="http://www.example.com">')
    end
  end
end
