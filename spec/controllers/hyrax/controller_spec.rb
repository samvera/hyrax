describe Hyrax::Controller do
  let(:mock_controller) { ApplicationController.new { described_class } }
  subject { mock_controller.mimes_for_respond_to }
  it 'responds to json' do
    expect(subject.key?(:json)).to be_truthy
  end
  it 'responds to html' do
    expect(subject.key?(:html)).to be_truthy
  end
end
