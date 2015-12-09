require 'spec_helper'

describe API::ItemsController, type: :controller do
  before do
    # Don't test characterization on these items; it breaks TravisCI and it's slow
    allow(CharacterizeJob).to receive(:perform_later)
  end

  let(:user) { FactoryGirl.find_or_create(:jill) }
  let!(:default_work) do
    GenericWork.create(title: ['Foo Bar']) do |gf|
      gf.apply_depositor_metadata(user)
      gf.arkivo_checksum = '6872d21557992f6ad1d07375f19fbfaf'
    end
  end

  subject { response }

  context 'with an HTTP GET or HEAD' do
    let(:token) { user.arkivo_token }
    let(:item) { FactoryGirl.json(:post_item, token: token) }
    let(:item_hash) { JSON.parse(item) }

    context 'with a missing token' do
      before { get :show, format: :json, id: default_work.id }

      specify do
        expect(subject).to have_http_status(401)
        expect(subject.body).to include('invalid user token:')
      end
    end

    context 'with an unfamiliar token' do
      before { get :show, format: :json, id: default_work.id, token: get_token }
      let(:get_token) { 'foobar' }

      specify do
        expect(subject).to have_http_status(401)
        expect(subject.body).to include("invalid user token: #{get_token}")
      end
    end

    context 'with an unauthorized resource' do
      before do
        allow_any_instance_of(User).to receive(:can?).with(:edit, default_work) { false }
        get :show, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(401)
        expect(assigns[:work]).to eq default_work
        expect(subject.body).to include("#{user} lacks access to #{default_work}")
      end
    end

    context 'with a resource not deposited via Arkivo' do
      before do
        allow_any_instance_of(GenericWork).to receive(:arkivo_checksum) { nil }
        get :show, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(403)
        expect(subject.body).to include("Forbidden: #{default_work} not deposited via Arkivo")
      end
    end

    context 'with a resource not found in the repository' do
      before do
        allow(GenericWork).to receive(:find).with(default_work.id).and_raise(ActiveFedora::ObjectNotFoundError)
        get :show, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(404)
        expect(subject.body).to include("id '#{default_work.id}' not found")
      end
    end

    context 'with an authorized Arkivo-deposited resource' do
      before { get :show, format: :json, id: default_work.id, token: token }

      specify do
        expect(subject).to have_http_status(204)
        expect(subject.body).to be_blank
      end
    end
  end

  context 'with an HTTP POST' do
    context 'without an item' do
      before { post :create, format: :json }

      specify do
        expect(subject).to have_http_status(400)
        expect(subject.body).to include('no item parameter')
      end
    end

    context 'with an invalid item' do
      before { post :create, item, format: :json }
      let(:item) { { foo: 'bar' }.to_json }

      specify do
        expect(subject).to have_http_status(400)
        expect(subject.body).to include('The property \'#/\' did not contain a required property of \'token\'')
      end
    end

    context 'with a valid item and matching token' do
      before { expect { post :create, item, format: :json }.to change { GenericWork.count }.by(1) }

      let(:deposited_file) { FileSet.where(label: item_hash['file']['filename']).take }
      let!(:deposited_work) { deposited_file.in_works.first }
      let(:token) { user.arkivo_token }
      let(:item) { FactoryGirl.json(:post_item, token: token) }
      let(:item_hash) { JSON.parse(item) }

      specify do
        expect(response).to be_success
        expect(response.status).to eq 201
        expect(response.headers['Location']).to match %r{/api/items/.{9}}
        expect(deposited_file).not_to be_nil
        expect(deposited_work.arkivo_checksum).to eq item_hash['file']['md5']
        expect(deposited_file.original_file.content).to eq "arkivo\n"
        expect(deposited_work.resource_type).to eq [item_hash['metadata']['resourceType']]
        expect(deposited_work.title).to eq [item_hash['metadata']['title']]
        expect(deposited_work.description).to eq [item_hash['metadata']['description']]
        expect(deposited_work.publisher).to eq [item_hash['metadata']['publisher']]
        expect(deposited_work.date_created).to eq [item_hash['metadata']['dateCreated']]
        expect(deposited_work.based_near).to eq [item_hash['metadata']['basedNear']]
        expect(deposited_work.identifier).to eq [item_hash['metadata']['identifier']]
        expect(deposited_work.related_url).to eq [item_hash['metadata']['url']]
        expect(deposited_work.language).to eq [item_hash['metadata']['language']]
        expect(deposited_work.rights).to eq [item_hash['metadata']['rights']]
        expect(deposited_work.tag).to match_array item_hash['metadata']['tags']
        expect(deposited_work.creator).to match_array ['Doe, John', 'Babs McGee']
        expect(deposited_work.contributor).to match_array ['Nadal, Rafael', 'Jane Doeski']
      end
    end

    context 'with a valid item and unfamiliar token' do
      before { post :create, item, format: :json }

      let(:token) { 'unfamiliar_token' }
      let(:item) { FactoryGirl.json(:post_item, token: token) }

      specify do
        expect(response).not_to be_success
        expect(subject.status).to eq 401
        expect(subject.body).to include("invalid user token: #{token}")
      end
    end
  end

  context 'with an HTTP PUT' do
    let(:post_deposited_file) { FileSet.where(label: post_item_hash['file']['filename']).take }
    let(:post_deposited_work) { post_deposited_file.in_works.first }
    let(:post_token) { user.arkivo_token }
    let(:post_item) { FactoryGirl.json(:post_item, token: post_token) }
    let(:post_item_hash) { JSON.parse(post_item) }

    before do
      expect { post :create, post_item, format: :json }.to change { GenericWork.count }.by(1)
    end

    context 'with a valid item, matching token, and authorized resource' do
      before { put :update, put_item, id: post_deposited_work.id, format: :json }

      let(:put_deposited_file) { post_deposited_file.reload }
      let(:put_deposited_work) { post_deposited_work.reload }
      let(:put_token) { user.arkivo_token }
      let(:put_item) { FactoryGirl.json(:put_item, token: put_token) }
      let(:put_item_hash) { JSON.parse(put_item) }

      specify do
        expect(subject).to be_success
        expect(subject.status).to eq 204
        expect(subject.body).to be_blank
        expect(put_deposited_work.arkivo_checksum).to eq put_item_hash['file']['md5']
        expect(put_deposited_file.original_file.content).to eq "# HEADER\n\nThis is a paragraph!\n"
        expect(put_deposited_work.resource_type).to eq [put_item_hash['metadata']['resourceType']]
        expect(put_deposited_work.title).to eq [put_item_hash['metadata']['title']]
        expect(put_deposited_work.rights).to eq [put_item_hash['metadata']['rights']]
        expect(put_deposited_work.tag).to eq put_item_hash['metadata']['tags']
        expect(put_deposited_work.creator).to eq ['Doe, John', 'Babs McGee']
        expect(put_deposited_work.description).to eq []
        expect(put_deposited_work.publisher).to eq []
        expect(put_deposited_work.date_created).to eq []
        expect(put_deposited_work.based_near).to eq []
        expect(put_deposited_work.identifier).to eq []
        expect(put_deposited_work.related_url).to eq []
        expect(put_deposited_work.language).to eq []
        expect(put_deposited_work.contributor).to eq []
      end
    end

    context 'with a valid item, matching token, authorized resource, but not Arkivo-deposited' do
      before do
        allow_any_instance_of(GenericWork).to receive(:arkivo_checksum) { nil }
        put :update, item, id: post_deposited_work.id, format: :json
      end

      let(:item) { FactoryGirl.json(:put_item, token: post_token) }

      specify do
        expect(subject).not_to be_success
        expect(subject.status).to eq 403
        expect(subject.body).to include("Forbidden: #{post_deposited_work} not deposited via Arkivo")
      end
    end

    context 'with a valid item, matching token, missing resource' do
      before do
        allow(GenericWork).to receive(:find).with(post_deposited_work.id) do
          raise(ActiveFedora::ObjectNotFoundError)
        end
        put :update, item, id: post_deposited_work.id, format: :json
      end

      let(:item) { FactoryGirl.json(:put_item, token: post_token) }

      specify do
        expect(subject).to have_http_status(404)
        expect(subject.body).to include("id '#{post_deposited_work.id}' not found")
      end
    end

    context 'with a valid item, matching token, and unauthorized resource' do
      before do
        allow_any_instance_of(User).to receive(:can?).with(:edit, post_deposited_work) { false }
        put :update, item, id: post_deposited_work.id, format: :json
      end

      let(:item) { FactoryGirl.json(:put_item, token: post_token) }

      specify do
        expect(subject).not_to be_success
        expect(assigns[:work]).to eq post_deposited_work
        expect(subject.status).to eq 401
        expect(subject.body).to include("#{user} lacks access to #{post_deposited_work}")
      end
    end

    context 'with a valid item and unfamiliar token' do
      before { put :update, item, id: post_deposited_work.id, format: :json }

      let(:token) { 'unfamiliar_token' }
      let(:item) { FactoryGirl.json(:put_item, token: token) }

      specify do
        expect(subject).not_to be_success
        expect(subject.status).to eq 401
        expect(subject.body).to include("invalid user token: #{token}")
      end
    end

    context 'with an invalid item' do
      before { put :update, item, id: post_deposited_work.id, format: :json }
      let(:item) { { foo: 'bar' }.to_json }

      specify do
        expect(subject).to have_http_status(400)
        expect(subject.body).to include('The property \'#/\' did not contain a required property of \'token\'')
      end
    end
  end

  context 'with an HTTP DELETE' do
    before { post :create, item, format: :json }

    let(:token) { user.arkivo_token }
    let(:item) { FactoryGirl.json(:post_item, token: token) }
    let(:item_hash) { JSON.parse(item) }

    context 'with a missing token' do
      before { delete :destroy, format: :json, id: default_work.id }

      specify do
        expect(subject).to have_http_status(401)
        expect(subject.body).to include('invalid user token:')
      end
    end

    context 'with an unfamiliar token' do
      before { delete :destroy, format: :json, id: default_work.id, token: delete_token }
      let(:delete_token) { 'foobar' }

      specify do
        expect(subject).to have_http_status(401)
        expect(subject.body).to include("invalid user token: #{delete_token}")
      end
    end

    context 'with an unauthorized resource' do
      before do
        allow_any_instance_of(User).to receive(:can?).with(:edit, default_work) { false }
        delete :destroy, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(401)
        expect(assigns[:work]).to eq default_work
        expect(subject.body).to include("#{user} lacks access to #{default_work}")
      end
    end

    context 'with a resource not deposited via Arkivo' do
      before do
        allow_any_instance_of(GenericWork).to receive(:arkivo_checksum) { nil }
        delete :destroy, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(403)
        expect(subject.body).to include("Forbidden: #{default_work} not deposited via Arkivo")
      end
    end

    context 'with a resource not found in the repository' do
      before do
        allow(GenericWork).to receive(:find).with(default_work.id).and_raise(ActiveFedora::ObjectNotFoundError)
        delete :destroy, format: :json, id: default_work.id, token: token
      end

      specify do
        expect(subject).to have_http_status(404)
        expect(subject.body).to include("id '#{default_work.id}' not found")
      end
    end

    context 'with an authorized Arkivo-deposited resource' do
      before do
        expect { delete :destroy, format: :json, id: default_work.id, token: token }.to change { GenericWork.count }.by(-1)
      end

      specify do
        expect(subject).to have_http_status(204)
        expect(subject.body).to be_blank
      end
    end
  end
end
