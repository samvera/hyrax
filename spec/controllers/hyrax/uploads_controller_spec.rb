# frozen_string_literal: true
RSpec.describe Hyrax::UploadsController do
  let(:user) { create(:user) }
  let(:chunk) { fixture_file_upload('/world.png', 'image/png') }

  describe "#create" do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let!(:existing_file) { create(:uploaded_file, file: file, user: user) }

    context "when signed in" do
      before do
        sign_in user
      end

      it "is successful" do
        post :create, params: { files: [file], format: 'json' }
        expect(response).to be_successful
        expect(assigns(:upload)).to be_kind_of Hyrax::UploadedFile
        expect(assigns(:upload)).to be_persisted
        expect(assigns(:upload).user).to eq user
      end

      context "when uploading in chunks" do
        it "appends chunks in correct sequence" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)

          initial_size = original_upload.file.size
          request.headers['CONTENT-RANGE'] = "bytes #{initial_size}-#{initial_size + original_file.size - 1}/5000"
          first_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [first_chunk], id: original_upload.id, format: 'json' }
          original_upload.reload
          expected_size_after_first_chunk = initial_size * 2
          expect(original_upload.file.size).to eq(expected_size_after_first_chunk)

          request.headers['CONTENT-RANGE'] = "bytes #{initial_size * 2}-#{(initial_size * 2) + original_file.size - 1}/5000"
          second_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [second_chunk], id: original_upload.id, format: 'json' }
          original_upload.reload
          expected_size_after_second_chunk = initial_size * 3
          expect(original_upload.file.size).to eq(expected_size_after_second_chunk)
        end

        it "replaces file if chunks are mismatched" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)
          original_content = File.read(original_upload.file.path)

          request.headers['CONTENT-RANGE'] = 'bytes 2000-2999/5000'
          different_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [different_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          new_content = File.read(original_upload.file.path)
          expect(new_content).not_to eq(original_content)
        end

        it "updates the file size after replacing mismatched chunks" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)
          original_size = original_upload.file.size

          request.headers['CONTENT-RANGE'] = 'bytes 2000-2999/5000'
          different_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [different_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          new_size = original_upload.file.size
          expect(new_size).not_to eq(original_size)
        end

        it "does not append mismatched chunks" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)

          request.headers['CONTENT-RANGE'] = 'bytes 0-999/5000'
          first_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [first_chunk], id: original_upload.id, format: 'json' }

          request.headers['CONTENT-RANGE'] = 'bytes 3000-3999/5000'
          out_of_order_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [out_of_order_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          expect(original_upload.file.size).not_to eq(4000)
        end
      end
    end

    context "when not signed in" do
      it "is unauthorized" do
        post :create, params: { files: [file], format: 'json' }
        expect(response.status).to eq 401
      end
    end

    context "with the :active_storage backend" do
      render_views

      around do |example|
        original = Hyrax.config.uploaded_file_storage_backend
        Hyrax.config.uploaded_file_storage_backend = :active_storage
        example.run
        Hyrax.config.uploaded_file_storage_backend = original
      end

      before { sign_in user }

      let(:fixture_bytes) { File.binread(fixture_path + '/world.png') }

      def precreate_upload(name = 'world.png')
        post :create, params: { files: [name], format: 'json' }
        assigns(:upload)
      end

      def chunk_upload(upload, bytes, first_byte, total)
        chunk_path = File.join(Dir.mktmpdir, 'chunk')
        File.binwrite(chunk_path, bytes)
        request.headers['CONTENT-RANGE'] = "bytes #{first_byte}-#{first_byte + bytes.bytesize - 1}/#{total}"
        post :create,
             params: { files: [Rack::Test::UploadedFile.new(chunk_path, 'image/png')],
                       id: upload.id, format: 'json' }
      end

      it "creates a record from a filename ahead of the content" do
        upload = precreate_upload

        expect(response).to be_successful
        expect(upload).to be_persisted
        expect(upload.filename).to eq 'world.png'
        expect(upload).not_to be_stored
        expect(JSON.parse(response.body)['files'].first['name']).to eq 'world.png'
      end

      it "attaches content sent in a single request" do
        upload = precreate_upload

        post :create, params: { files: [fixture_file_upload('/world.png', 'image/png')],
                                id: upload.id, format: 'json' }

        expect(response).to be_successful
        upload.reload
        expect(upload).to be_stored
        expect(upload.byte_size).to eq fixture_bytes.bytesize
        expect(upload.with_io(&:read)).to eq fixture_bytes
      end

      it "assembles sequential chunks and attaches the completed file" do
        upload = precreate_upload
        midpoint = fixture_bytes.bytesize / 2
        total = fixture_bytes.bytesize

        chunk_upload(upload, fixture_bytes[0...midpoint], 0, total)
        expect(response).to be_successful
        expect(upload.reload).not_to be_stored

        chunk_upload(upload, fixture_bytes[midpoint..], midpoint, total)
        expect(response).to be_successful

        upload.reload
        expect(upload).to be_stored
        expect(upload.filename).to eq 'world.png'
        expect(upload.with_io(&:read)).to eq fixture_bytes
      end

      it "removes the assembly staging file after attaching" do
        upload = precreate_upload
        staging_file = File.join(Hyrax.config.cache_path.call.to_s, 'chunked_uploads', "#{upload.id}.part")

        chunk_upload(upload, fixture_bytes, 0, fixture_bytes.bytesize)

        expect(upload.reload).to be_stored
        expect(File).not_to exist(staging_file)
      end

      it "restarts assembly when a chunk does not continue the pending data" do
        upload = precreate_upload
        total = fixture_bytes.bytesize + 1000

        chunk_upload(upload, fixture_bytes[0...100], 0, total)
        # out-of-order chunk: restarts the assembly rather than appending
        chunk_upload(upload, fixture_bytes[0...50], 500, total)

        staging_file = File.join(Hyrax.config.cache_path.call.to_s, 'chunked_uploads', "#{upload.id}.part")
        expect(File.size(staging_file)).to eq 50
        expect(upload.reload).not_to be_stored
      end
    end
  end

  describe "#destroy" do
    let(:file) { File.open(fixture_path + '/world.png') }
    let(:uploaded_file) { create(:uploaded_file, file: file, user: user) }

    context "when signed in" do
      before do
        sign_in user
      end

      it "destroys the uploaded file" do
        delete :destroy, params: { id: uploaded_file }
        expect(response.status).to eq 204
        expect(assigns[:upload]).to be_destroyed
        expect(File.exist?(uploaded_file.file.file.file)).to be false
      end

      context "for a file that doesn't belong to me" do
        let(:uploaded_file) { create(:uploaded_file, file: file) }

        it "doesn't destroy" do
          delete :destroy, params: { id: uploaded_file }
          expect(response.status).to eq 401
        end
      end
    end

    context "when not signed in" do
      it "is redirected to sign in" do
        delete :destroy, params: { id: uploaded_file }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end

    context "with the :active_storage backend" do
      around do |example|
        original = Hyrax.config.uploaded_file_storage_backend
        Hyrax.config.uploaded_file_storage_backend = :active_storage
        example.run
        Hyrax.config.uploaded_file_storage_backend = original
      end

      before { sign_in user }

      it "destroys the record and purges the attachment" do
        uploaded_file = Hyrax::UploadedFile.create(file: file, user: user)

        expect { delete :destroy, params: { id: uploaded_file } }
          .to have_enqueued_job(ActiveStorage::PurgeJob)
        expect(response.status).to eq 204
        expect(assigns[:upload]).to be_destroyed
      end
    end
  end
end
