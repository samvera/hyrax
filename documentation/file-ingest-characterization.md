# File Ingest and Characterization in Hyrax

This document describes how files are ingested, characterized, and processed in Hyrax, with explicit coverage of both the **ActiveFedora** (legacy actor-stack) path and the **Valkyrie** (resource/transaction) path.  It is intended for developers who need to trace, debug, or modify these flows.

> **Scope:** Hyrax supports two persistence back-ends.  The _ActiveFedora_ path stores files directly in a Fedora repository via Hydra/LDP.  The _Valkyrie_ path stores files via a pluggable `Valkyrie::StorageAdapter` and persists metadata through the Valkyrie persister/query-service stack.  Wings is the compatibility shim that lets ActiveFedora objects participate in Valkyrie workflows.

---

## Table of Contents

1. [Shared Concepts](#1-shared-concepts)
2. [ActiveFedora Ingest Path](#2-activefedora-ingest-path)
   - [Actor Stack Entry Point](#21-actor-stack-entry-point)
   - [File Attachment Job](#22-file-attachment-job)
   - [FileSet and FileActor](#23-fileset-and-fileactor)
   - [IngestJob and JobIoWrapper](#24-ingestjob-and-jobiowrapper)
3. [Valkyrie Ingest Path](#3-valkyrie-ingest-path)
   - [Transaction Entry Point](#31-transaction-entry-point)
   - [WorkUploadsHandler](#32-workuploadshandler)
   - [ValkyrieIngestJob and ValkyrieUpload](#33-valkyrieingestjob-and-valkyrieupload)
4. [File Characterization](#4-file-characterization)
   - [ActiveFedora Characterization](#41-activefedora-characterization)
   - [Valkyrie Characterization](#42-valkyrie-characterization)
5. [Derivative Generation](#5-derivative-generation)
   - [ActiveFedora Derivatives](#51-activefedora-derivatives)
   - [Valkyrie Derivatives](#52-valkyrie-derivatives)
   - [Derivative Service Factory](#53-derivative-service-factory)
6. [Event System (The Connective Tissue)](#6-event-system-the-connective-tissue)
7. [Metadata Persistence and Indexing](#7-metadata-persistence-and-indexing)
8. [Wings: The AF ↔ Valkyrie Bridge](#8-wings-the-af--valkyrie-bridge)
9. [Key Configuration Points](#9-key-configuration-points)
10. [Developer Cautions](#10-developer-cautions)

---

## 1. Shared Concepts

### Hyrax::UploadedFile

`app/models/hyrax/uploaded_file.rb`

All file uploads, regardless of back-end, start as an `Hyrax::UploadedFile` ActiveRecord record.  CarrierWave mounts a `UploadedFileUploader` on the `:file` column.

```ruby
# Relates uploaded file to a file set after creation
def add_file_set!(file_set)
  # Sets file_set_uri based on whether file_set is AF or Valkyrie
end
```

Key columns: `file` (CarrierWave uploader), `user_id`, `file_set_uri`.

The `file_set_uri` is used for idempotency: both the AF and Valkyrie paths skip files whose `file_set_uri` is already set, preventing duplicate ingest on job retries.

### JobIoWrapper

`app/models/job_io_wrapper.rb`

A serializable ActiveRecord shim that wraps a file so it can be passed to ActiveJob without losing file-system context.  Used exclusively in the AF path.

Key fields: `path`, `file_set_id`, `relation` (`:original_file`, etc.), `original_name`, `mime_type`, `uploaded_file_id`.

```ruby
# Factory used by FileSetActor
JobIoWrapper.create_with_varied_file_handling!(
  user:, file:, relation:, file_set:, use_valkyrie:
)

# Called by IngestJob
wrapper.ingest_file  # delegates to FileActor#ingest_file
```

### Hyrax::FileMetadata (Valkyrie only)

`app/models/hyrax/file_metadata.rb`

A `Valkyrie::Resource` that records metadata about a single file attached to a FileSet.  There is no AF equivalent; AF stores file properties directly on the `Hydra::PCDM::File` LDP resource.

Key attributes: `file_identifier` (Valkyrie storage-adapter ID), `file_set_id`, `pcdm_use` (array of `RDF::URI` use constants from `Hyrax::FileMetadata::Use`), `mime_type`, `original_filename`, `recorded_size`, characterization properties (`height`, `width`, `file_size`, `format_label`, etc.).

Use constants (defined under `Hyrax::FileMetadata::Use`):

| Constant | Purpose |
|----------|---------|
| `ORIGINAL_FILE` | The uploaded/original file |
| `THUMBNAIL_IMAGE` | Thumbnail derivative |
| `EXTRACTED_TEXT` | Full-text extraction |
| `INTERMEDIATE_FILE` | Intermediate processing copy |
| `PRESERVATION_FILE` | Long-term preservation copy |
| `SERVICE_FILE` | Access/service copy |
| `TRANSCRIPT` | Transcript |

---

## 2. ActiveFedora Ingest Path

### 2.1 Actor Stack Entry Point

`app/services/hyrax/default_middleware_stack.rb`

The ActorStack is a middleware chain that processes work create/update operations.  Each actor calls `next_actor.create(env)` (or `update`) to pass control down the chain.

Relevant actors in default order:

```
Hyrax::Actors::OptimisticLockValidator
Hyrax::Actors::CreateWithRemoteFilesActor
Hyrax::Actors::CreateWithFilesActor          ← triggers file attachment
Hyrax::Actors::CollectionsMembershipActor
Hyrax::Actors::AddToWorkActor
Hyrax::Actors::AttachMembersActor
Hyrax::Actors::ApplyOrderActor
Hyrax::Actors::DefaultAdminSetActor
Hyrax::Actors::InterpretVisibilityActor
Hyrax::Actors::TransferRequestActor
Hyrax::Actors::ApplyPermissionTemplateActor
Hyrax::Actors::CleanupFileSetsActor
Hyrax::Actors::CleanupTrophiesActor
Hyrax::Actors::FeaturedWorkActor
Hyrax::Actors::ModelActor                    ← final AF persistence
```

`app/actors/hyrax/actors/create_with_files_actor.rb`

`CreateWithFilesActor` extracts `uploaded_file_ids` from `env.attributes`, validates all are `Hyrax::UploadedFile` records, calls the next actor to persist the work, and then enqueues `AttachFilesToWorkJob`:

```ruby
def create(env)
  uploaded_file_ids = env.attributes.delete(:uploaded_files)
  # ... validation ...
  next_actor.create(env) &&
    AttachFilesToWorkJob.perform_later(env.curation_concern, uploaded_files)
end
```

### 2.2 File Attachment Job

`app/jobs/attach_files_to_work_job.rb`

`AttachFilesToWorkJob` is the routing point between AF and Valkyrie:

```ruby
def perform(work, uploaded_files, **work_attributes)
  case work
  when ActiveFedora::Base
    perform_af(work, uploaded_files, work_attributes)   # AF path
  else
    Hyrax::WorkUploadsHandler.new(work: work)           # Valkyrie path
      .add(files: uploaded_files)
      .attach
  end
end
```

The AF branch (`perform_af`) loops over `uploaded_files`, skipping any with an existing `file_set_uri`, and for each remaining file:

1. Instantiates a new `FileSet` (AF model) and a `Hyrax::Actors::FileSetActor`.
2. Calls `actor.create_metadata(visibility_attrs)` — sets depositor, dates, visibility.
3. Calls `actor.create_content(uploaded_file)` — queues `IngestJob`.
4. Calls `actor.attach_to_work(work, metadata)` — acquires a lock, appends the FileSet to `work.ordered_members`, and fires the `:after_create_fileset` callback.

### 2.3 FileSet and FileActor

`app/actors/hyrax/actors/file_set_actor.rb`

```ruby
# Creates metadata on the file_set and saves it
def create_metadata(file_set_params = {})
  file_set.depositor = user.user_key
  # ... dates, creator, visibility via actor stack ...
end

# Queues ingest for the file
def create_content(file, relation = :original_file, from_url: false)
  # sets label/title from filename
  # saves file_set
  # unless from_url: IngestJob.perform_later(wrapper)
  # if from_url: FileActor.ingest_file(file); then visibility/permission jobs
end

# Appends file_set to work with lock
def attach_to_work(work, file_set_params = {})
  acquire_lock_for(work.id) do
    work.ordered_members << file_set
    work.representative_id ||= file_set.id
    work.thumbnail_id ||= file_set.id
    work.save!
  end
  Hyrax.publisher.publish('file.set.attached', file_set: file_set, user: user)
end
```

`app/actors/hyrax/actors/file_actor.rb`

`FileActor` performs the actual LDP write:

```ruby
def ingest_file(io)
  io.use_valkyrie = false  # forces AF objects even in mixed environments

  Hydra::Works::AddFileToFileSet.call(file_set, io, relation, versioning: false)
  return false unless file_set.save

  repository_file = related_file  # the Hydra::PCDM::File LDP node
  create_version(repository_file, user)  # via Hyrax::VersioningService
  CharacterizeJob.perform_later(file_set, repository_file.id, pathhint(io))
end
```

`Hydra::Works::AddFileToFileSet` is a `hydra-works` gem operation that streams the file content to Fedora via LDP.

### 2.4 IngestJob and JobIoWrapper

`app/jobs/ingest_job.rb`

```ruby
class IngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  def perform(wrapper, notification: false)
    wrapper.ingest_file   # calls FileActor#ingest_file → CharacterizeJob
    ContentNewVersionEventJob.perform_later(wrapper.file_set_id, ...) if notification
  end
end
```

`IngestJob` accepts a `JobIoWrapper`, which is serialized to the job queue.  `wrapper.ingest_file` delegates back to `Hyrax::Actors::FileActor#ingest_file`.

**Full AF ingest sequence:**

```
CreateWithFilesActor#create
  └─ AttachFilesToWorkJob (async)
       └─ FileSetActor#create_metadata
       └─ FileSetActor#create_content
            └─ IngestJob (async)
                 └─ JobIoWrapper#ingest_file
                      └─ FileActor#ingest_file
                           └─ Hydra::Works::AddFileToFileSet  (writes to Fedora)
                           └─ VersioningService#create
                           └─ CharacterizeJob (async)  →  see §4.1
```

---

## 3. Valkyrie Ingest Path

### 3.1 Transaction Entry Point

`lib/hyrax/transactions/work_create.rb`

The Valkyrie path uses `Dry::Transaction`-style step chains instead of an actor stack.

Default steps for `Hyrax::Transactions::WorkCreate`:

```
change_set.set_default_admin_set
change_set.ensure_admin_set
change_set.set_user_as_depositor
change_set.apply
work_resource.apply_permission_template
work_resource.save_acl
work_resource.add_file_sets          ← file handling
work_resource.change_depositor
work_resource.add_to_parent
work_resource.sync_redirect_paths
```

`lib/hyrax/transactions/steps/add_file_sets.rb`

```ruby
def call(obj, uploaded_files: [], file_set_params: [])
  # delegates entirely to WorkUploadsHandler
  Hyrax::WorkUploadsHandler.new(work: obj)
    .add(files: uploaded_files, file_set_params: file_set_params)
    .attach
  # then propagates embargo/lease to file_sets
  Success(obj)
end
```

### 3.2 WorkUploadsHandler

`app/services/hyrax/work_uploads_handler.rb`

This is the Valkyrie orchestrator.  Its public API is:

```ruby
Hyrax::WorkUploadsHandler.new(work: my_work)
  .add(files: [file1, file2], file_set_params: [...])
  .attach
```

`add` validates all files are `Hyrax::UploadedFile` and discards those with an existing `file_set_uri` (idempotency guard).

`attach` acquires a Redis/Redlock lock on the work ID, then for each file:

```ruby
# private make_file_set_and_ingest
def make_file_set_and_ingest(file, file_set_params = {})
  file_set = @persister.save(
    resource: Hyrax.config.valkyrie_file_set_class.new(file_set_args(file, file_set_params))
  )
  Hyrax.publisher.publish('object.deposited', object: file_set, user: file.user)
  file.add_file_set!(file_set)                              # sets UploadedFile#file_set_uri
  Hyrax::AccessControlList.copy_permissions(source: work_acl, target: file_set)
  append_to_work(file_set)                                  # work.member_ids << file_set.id
  { file_set: file_set, user: file.user, job: ValkyrieIngestJob.new(file) }
end
```

After all file_sets are created, `attach` saves the work (with updated `member_ids`), publishes `'object.metadata.updated'`, then enqueues each `ValkyrieIngestJob` and publishes `'file.set.attached'`.

### 3.3 ValkyrieIngestJob and ValkyrieUpload

`app/jobs/valkyrie_ingest_job.rb`

```ruby
class ValkyrieIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  def perform(file, pcdm_use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
    file_set = Hyrax.query_service.find_by(id: Valkyrie::ID.new(file.file_set_uri))
    upload_file(file: file, file_set: file_set, pcdm_use: pcdm_use, user: file.user)
  end
end
```

`upload_file` calls `Hyrax::ValkyrieUpload.file(...)`.

`app/services/hyrax/valkyrie_upload.rb`

`ValkyrieUpload` is the Valkyrie equivalent of `FileActor#ingest_file`:

```ruby
def upload(io:, filename:, file_set:, pcdm_use:, use_valkyrie: Hyrax.config.use_valkyrie?)
  # 1. Handle versioning if storage adapter supports it
  if pcdm_use == ORIGINAL_FILE && file_set.original_file_id && adapter.supports?(:versions)
    streamfile = adapter.upload_version(id: file_set.original_file_id, file: io)
  else
    streamfile = adapter.upload(file: io, original_filename: filename, resource: file_set)
  end

  # 2. Create and persist FileMetadata
  file_metadata = Hyrax::FileMetadata.new(
    file_identifier: streamfile.id,
    file_set_id:     file_set.id,
    pcdm_use:        [pcdm_use],
    mime_type:       streamfile.content_type,
    original_filename: filename,
    recorded_size:   [streamfile.size]
  )
  Hyrax.persister.save(resource: file_metadata)

  # 3. Update file_set.file_ids
  file_set.file_ids += [file_metadata.id]
  # (title/label also set from filename)
  Hyrax.persister.save(resource: file_set)

  # 4. Publish events (triggers characterization via FileListener)
  Hyrax.publisher.publish('file.uploaded',          metadata: file_metadata)
  Hyrax.publisher.publish('file.metadata.updated',  metadata: file_metadata, user: user)
  Hyrax.publisher.publish('object.membership.updated', object: file_set, user: user)
end
```

The storage adapter (`Hyrax.storage_adapter`) is configurable — common choices are the disk adapter (development), an S3 adapter, or a Fedora 6 adapter via the Valkyrie Fedora gem.

**Full Valkyrie ingest sequence:**

```
WorkCreate transaction
  └─ Steps::AddFileSets
       └─ WorkUploadsHandler#attach (with Redis lock)
            └─ persister.save(FileSet)          (creates Valkyrie FileSet)
            └─ AccessControlList.copy_permissions
            └─ ValkyrieIngestJob (enqueued)
                 └─ ValkyrieUpload#upload
                      └─ storage_adapter.upload  (writes bytes to storage backend)
                      └─ persister.save(FileMetadata)
                      └─ persister.save(FileSet)
                      └─ publisher.publish('file.uploaded')  →  FileListener → ValkyrieCharacterizationJob
```

---

## 4. File Characterization

Characterization extracts technical metadata (MIME type, dimensions, checksum, format label, etc.) from the stored file.  Both paths ultimately rely on FITS (via `Hydra::FileCharacterization` and `Hydra::Works::CharacterizationService`), but they wrap it differently.

### 4.1 ActiveFedora Characterization

`app/jobs/characterize_job.rb`

Triggered directly from `FileActor#ingest_file`:

```ruby
CharacterizeJob.perform_later(file_set, repository_file.id, pathhint)
```

```ruby
def perform(file_set, file_id, filepath = nil)
  # Ensure file is on disk (downloads from Fedora if needed)
  filepath ||= Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id)
  return unless file_set.characterization_proxy?
  characterize(file_set, file_id, filepath)
  Hyrax.publisher.publish('file.characterized', file_set: file_set,
                           file_id: file_id, path_hint: filepath)
end

def characterize(file_set, _file_id, filepath)
  # Clear old values first (important — see §10)
  clear_metadata(file_set)

  # Run FITS via Hydra::Works
  CharacterizeJob.characterization_service.run(
    file_set.characterization_proxy, filepath, **Hyrax.config.characterization_options
  )

  file_set.characterization_proxy.save!
  file_set.update_index
  file_set.save  # persists date_modified etc.
end
```

Default `characterization_service` is `Hydra::Works::CharacterizationService`.  The FITS result is parsed and properties are set directly on the `Hydra::PCDM::File` LDP object (the `characterization_proxy`).

Properties written to the proxy include: `format_label`, `file_size`, `height`, `width`, `filename`, `well_formed`, `valid`, `date_created`, `fits_version`, `exif_version`, `checksum`, `character_set`, `markup_basis`, `markup_language`, `byte_order`, `compression`, `color_space`, `profile_name`, `profile_version`, `orientation`, `color_map`, `image_producer`, `capture_device`, `scanning_software`, `gps_timestamp`, `latitude`, `longitude`, `file_title`, `creator`, `page_count`, `language`, `word_count`, `character_count`, `line_count`, `graphics_count`, `data_format`, `offset`, `alpha_channels` (if IIIF enabled), `duration`, `sample_rate`, and others.

### 4.2 Valkyrie Characterization

`app/jobs/valkyrie_characterization_job.rb`

Triggered by the event `'file.uploaded'` via `FileListener`:

```ruby
class ValkyrieCharacterizationJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  def perform(file_metadata_id)
    metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_metadata_id)
    Hyrax.config.characterization_service.run(
      metadata: metadata,
      file:     metadata.file,           # retrieved from storage_adapter
      user:     metadata.file_set.depositor
    )
  end
end
```

`app/services/hyrax/characterization/valkyrie_characterization_service.rb`

```ruby
def self.run(metadata:, file:, user:, **options)
  new(metadata, file, user, **options).tap do |service|
    service.characterize
    Hyrax.persister.save(resource: metadata)
    Hyrax.publisher.publish('file.metadata.updated', metadata: metadata, user: user)
    Hyrax.publisher.publish('file.characterized',
      file_set: metadata.file_set, file_id: metadata.id.to_s, path_hint: file.disk_path)
  end
end
```

Internally uses the same FITS toolchain (`Hydra::FileCharacterization`) but maps results to `FileMetadata` attributes rather than to PCDM file properties.  Key differences:

- `mime_type` is set to the **last** value returned (FITS may return multiple).
- `height` and `width` are set to the **maximum** value (handles multi-page documents).
- Results are persisted via `Hyrax.persister.save(resource: metadata)`.

Configurable via `Hyrax.config.characterization_service` (replace the default to use custom characterizers such as MediaInfo for AV files or Tika for documents).

---

## 5. Derivative Generation

Derivatives (thumbnails, web-friendly formats, extracted text) are created after characterization.

### 5.1 ActiveFedora Derivatives

`app/jobs/create_derivatives_job.rb`

Triggered by `'file.characterized'` event via `FileListener`:

```ruby
def perform(file_set, file_id, filepath = nil)
  return if Hyrax.config.disable_ffmpeg_check? # video guard
  filepath ||= Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id)
  file_set.create_derivatives(filepath)   # delegates to FileSetDerivativesService
  file_set.reload
  file_set.update_index
  work = file_set.parent
  work&.update_index if file_set.id == work&.thumbnail_id
end
```

`file_set.create_derivatives(filepath)` calls `Hyrax::FileSetDerivativesService#create_derivatives`, which dispatches by MIME type to format-specific processors (see §5.3).

### 5.2 Valkyrie Derivatives

`app/jobs/valkyrie_create_derivatives_job.rb`

Triggered by `'file.characterized'` event via `FileListener`:

```ruby
def perform(file_set_id, file_id, _filepath = nil)
  return if Hyrax.config.disable_ffmpeg_check?
  file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_id)
  file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
  Hyrax::DerivativeService.for(file_metadata).create_derivatives(file.disk_path)

  # Reindex parent work if this file set is the thumbnail
  reindex_parent(file_set_id)
end
```

The key difference: AF passes the `FileSet` object; Valkyrie passes a `FileMetadata` to the derivative service factory.

### 5.3 Derivative Service Factory

`app/services/hyrax/derivative_service.rb`

```ruby
def self.for(file_set, services: Hyrax.config.derivative_services)
  services.each do |service_class|
    service = service_class.new(file_set)
    return service if service.valid?
  end
  new(file_set)  # fallback to base service
end
```

Each service implements `#valid?` (checks MIME type), `#create_derivatives(filename)`, and `#cleanup_derivatives`.

`app/services/hyrax/file_set_derivatives_service.rb` — the default service:

| MIME type group | Derivatives created |
|-----------------|---------------------|
| `application/pdf` | Thumbnail (ImageMagick), full-text extraction (Solr) |
| Office documents (`application/msword`, etc.) | Thumbnail (LibreOffice → ImageMagick), full-text |
| Audio (`audio/*`) | MP3 (FFmpeg), OGG (FFmpeg) |
| Video (`video/*`) | JPG thumbnail (FFmpeg), WebM (FFmpeg), MP4 (FFmpeg) |
| Image (`image/*`) | JPG thumbnail (ImageMagick, layer 0 for pyramidal TIFF) |

Derivatives are stored at paths derived from `Hyrax::DerivativePath.derivative_path_for_reference`.

---

## 6. Event System (The Connective Tissue)

Hyrax uses `Dry::Events` (via `Hyrax::Publisher`) to decouple ingest stages.  Listeners are registered in `config/initializers/listeners.rb`.

### Events fired during ingest

| Event | Published by | Consumed by |
|-------|-------------|-------------|
| `'object.deposited'` | `WorkUploadsHandler` | Analytics, notifications |
| `'file.set.attached'` | `WorkUploadsHandler`, `FileSetActor#attach_to_work` | Analytics, notifications |
| `'file.uploaded'` | `ValkyrieUpload#upload` | `FileListener` → `ValkyrieCharacterizationJob` |
| `'file.metadata.updated'` | `ValkyrieUpload#upload`, `ValkyrieCharacterizationService` | `MetadataIndexListener` → Solr reindex |
| `'object.membership.updated'` | `ValkyrieUpload#upload` | `MetadataIndexListener` → Solr reindex |
| `'object.metadata.updated'` | `WorkUploadsHandler#attach` | `MetadataIndexListener` → Solr reindex |
| `'file.characterized'` | `CharacterizeJob`, `ValkyrieCharacterizationService` | `FileListener` → `Create[Valkyrie]DerivativesJob` |

### FileListener dispatch (AF vs Valkyrie)

`app/services/hyrax/listeners/file_listener.rb`

```ruby
def on_file_characterized(event)
  case event[:file_set]
  when ActiveFedora::Base
    CreateDerivativesJob.perform_later(event[:file_set], event[:file_id], event[:path_hint])
  else
    ValkyrieCreateDerivativesJob.perform_later(event[:file_set].id.to_s, event[:file_id])
  end
end

def on_file_uploaded(event)
  # Only for original files; respects skip_derivatives flag
  return if event.payload[:skip_derivatives] || !event[:metadata]&.original_file?
  ValkyrieCharacterizationJob.perform_later(event[:metadata].id.to_s)
end
```

`on_file_uploaded` is Valkyrie-only; the AF path triggers `CharacterizeJob` directly from `FileActor#ingest_file` without an event.

---

## 7. Metadata Persistence and Indexing

### ActiveFedora

- File properties live on the `Hydra::PCDM::File` LDP resource (a node within the FileSet in Fedora).
- `CharacterizeJob` writes properties directly to `file_set.characterization_proxy` and calls `file_set.update_index` to push to Solr.
- `CreateDerivativesJob` calls `file_set.reload` + `file_set.update_index` after creating derivatives.

### Valkyrie

- File properties live on `Hyrax::FileMetadata` resources persisted via `Hyrax.persister`.
- Solr indexing is event-driven: the `'file.metadata.updated'` event is consumed by `Hyrax::Listeners::MetadataIndexListener`.

`app/services/hyrax/listeners/metadata_index_listener.rb`

```ruby
def on_file_metadata_updated(event)
  Hyrax.index_adapter.save(resource: event[:metadata])
  # If this is the original file, reindex the parent file_set too
  if event[:metadata].original_file?
    file_set = Hyrax.query_service.find_by(id: event[:metadata].file_set_id)
    Hyrax.index_adapter.save(resource: file_set)
  end
end

def on_object_metadata_updated(event)
  Hyrax.index_adapter.save(resource: event[:object])
  # Reindex parent work if object is a thumbnail file_set
  ...
end
```

Custom queries for file lookup:

- `Hyrax.custom_queries.find_file_metadata_by(id:)` — single `FileMetadata`
- `Hyrax.custom_queries.find_many_file_metadata_by_use(resource:, use:)` — files by use predicate
- `Hyrax.custom_queries.find_original_file(file_set:)` — original file for a FileSet

---

## 8. Wings: The AF ↔ Valkyrie Bridge

Wings (`lib/wings/`) is a compatibility adapter that allows AF objects to be used in Valkyrie workflows by wrapping them as `Valkyrie::Resource` instances on the fly.  It is used when `Hyrax.config.use_valkyrie?` is true but the application still has AF-backed models.

Key components:

| File | Purpose |
|------|---------|
| `lib/wings/active_fedora_converter/` | Converts AF objects to Valkyrie resources |
| `lib/wings/valkyrie/` | Reverse: Valkyrie resources back to AF |
| `lib/wings/model_transformer.rb` | Model class mapping |
| `lib/wings/transformer_value_mapper.rb` | Property value mapping |
| `app/actors/hyrax/actors/file_actor.rb` | Explicitly forces `io.use_valkyrie = false` in the AF path to avoid using Valkyrie objects inadvertently |

`AttachFilesToWorkJob` performs the `case work` switch: AF objects are an `ActiveFedora::Base` instance; Valkyrie resources are not, even if Wings-wrapped.

The `'file.characterized'` event dispatch in `FileListener` uses the same `case` pattern: `when ActiveFedora::Base` routes to `CreateDerivativesJob`; otherwise routes to `ValkyrieCreateDerivativesJob`.

---

## 9. Key Configuration Points

`Hyrax.config` controls which path is taken at several junctions.  Relevant knobs:

| Config key | Type | Purpose |
|------------|------|---------|
| `use_valkyrie?` | Boolean | Master switch for Valkyrie path |
| `valkyrie_file_set_class` | Class | The `Hyrax::FileSet` subclass used by `WorkUploadsHandler` |
| `ingest_queue_name` | String/Symbol | ActiveJob queue for `IngestJob`, `ValkyrieIngestJob`, characterize, and derivatives jobs |
| `characterization_service` | Class | Replaced to customise characterization (e.g., swap out FITS) |
| `characterization_options` | Hash | Extra options forwarded to characterization service |
| `derivative_services` | Array<Class> | Priority-ordered list of derivative service classes; first `#valid?` wins |
| `extract_full_text?` | Boolean | Whether to run full-text extraction during derivatives |
| `enable_ffmpeg` | Boolean | Whether to run video/audio derivatives |
| `iiif_image_server?` | Boolean | Whether to write `alpha_channels` attribute during AF characterization |
| `file_set_file_service` | Class | Controls how files are located in the working directory |

Valkyrie-specific infrastructure:

| Accessor | Purpose |
|----------|---------|
| `Hyrax.storage_adapter` | `Valkyrie::StorageAdapter` for file content |
| `Hyrax.persister` | `Valkyrie::MetadataAdapter::Persister` for metadata |
| `Hyrax.query_service` | `Valkyrie::MetadataAdapter::QueryService` for reads |
| `Hyrax.index_adapter` | Solr-backed adapter for search indexing |
| `Hyrax.custom_queries` | Registry of domain-specific query handlers |

---

## 10. Developer Cautions

### Clearing characterization metadata before re-running FITS

`CharacterizeJob#clear_metadata` (AF path) explicitly resets all characterization properties to empty arrays before running FITS.  If this is skipped, old values from a previous characterization run can remain and produce incorrect Solr documents.  The Valkyrie path (`ValkyrieCharacterizationService#apply_metadata`) overwrites properties, but only those returned by FITS — stale values for _missing_ properties are not automatically cleared.

### `io.use_valkyrie = false` in FileActor

`FileActor#ingest_file` hard-codes `io.use_valkyrie = false` before calling `Hydra::Works::AddFileToFileSet`.  This is intentional: the AF actor path must write to Fedora LDP regardless of the `Hyrax.config.use_valkyrie?` flag.  Removing this line or making it conditional will break the AF ingest path.

### File idempotency guard

Both paths skip files whose `Hyrax::UploadedFile#file_set_uri` is already set.  This is an incomplete idempotency guard: if a job fails _after_ `add_file_set!` is called but _before_ the file is fully ingested, the record will be skipped on retry and the file will not be re-ingested.  Track [hyrax#TODO note in WorkUploadsHandler] when investigating stuck uploads.

### Lock scope

`WorkUploadsHandler` (Valkyrie) acquires a single Redlock on the work for the entire batch of file_sets.  `FileSetActor#attach_to_work` (AF) acquires a separate lock per file_set attachment.  If Redis is unavailable in the AF path, the lock silently degrades (check `Lockable`).

### Derivative ordering vs. characterization

Derivatives are triggered by the `'file.characterized'` event, not by `'file.uploaded'`.  If characterization is skipped (e.g., via `skip_derivatives: true` on `'file.uploaded'`), derivatives will also be skipped.  Some tests and bulk-ingest scripts pass `skip_derivatives: true` for performance; verify this flag is not accidentally retained in production workflows.

### Storage adapter `disk_path` requirement

`ValkyrieCreateDerivativesJob` calls `file.disk_path` on the storage-adapter result.  Not all storage adapters guarantee a disk path (e.g., a pure-S3 adapter may return a temporary local path or raise).  Verify your storage adapter's behaviour before using a non-disk-backed adapter in production; you may need to override the derivatives job to download the file locally first.

### Wings and Valkyrie FileMetadata

Wings wraps AF FileSet objects as Valkyrie resources, but the AF path never creates `Hyrax::FileMetadata` records.  Queries like `find_file_metadata_by` and `find_original_file` will return nothing for AF-backed file sets unless Wings re-projects the PCDM file graph.  Do not mix these query paths when operating on AF works.

### Listener registration order

`config/initializers/listeners.rb` registers listeners using `Hyrax.publisher.subscribe`.  If you add a custom listener that responds to `'file.uploaded'`, ensure it handles both the Valkyrie case (where `event[:metadata]` is a `Hyrax::FileMetadata`) and the AF case (where this event is never published — AF characterization is triggered synchronously in `FileActor`).

### Transaction steps vs. actor stack customization

Adding file-related behaviour to the AF path means modifying or inserting actors in `Hyrax.config.actor_middleware`.  Adding the equivalent to the Valkyrie path means adding a step to the `WorkCreate` (or `WorkUpdate`) transaction, or customizing `WorkUploadsHandler`.  These are separate extension points; changes to one do not affect the other.

---

## Appendix: Simplified Sequence Diagrams

### ActiveFedora

```
Browser/API → Work Form
  → CurationConcern::Actor (actor stack)
    → CreateWithFilesActor
      → AttachFilesToWorkJob [async]
          → FileSetActor#create_content
            → IngestJob [async]
              → FileActor#ingest_file
                → Hydra::Works::AddFileToFileSet  [Fedora LDP write]
                → VersioningService#create
                → CharacterizeJob [async]
                    → Hydra::Works::CharacterizationService [FITS]
                    → file_set.update_index  [Solr]
                    → publisher 'file.characterized'
                      → CreateDerivativesJob [async]
                          → FileSetDerivativesService
                          → file_set.update_index  [Solr]
```

### Valkyrie

```
Browser/API → Work Form / Transaction
  → Hyrax::Transactions::WorkCreate
    → Steps::AddFileSets
      → WorkUploadsHandler#attach [Redis lock]
          → persister.save(FileSet)
          → ValkyrieIngestJob [async]
              → ValkyrieUpload#upload
                → storage_adapter.upload  [storage backend write]
                → persister.save(FileMetadata)
                → publisher 'file.uploaded'
                  → ValkyrieCharacterizationJob [async]
                      → ValkyrieCharacterizationService [FITS]
                      → persister.save(FileMetadata)
                      → publisher 'file.metadata.updated'  → MetadataIndexListener → Solr
                      → publisher 'file.characterized'
                        → ValkyrieCreateDerivativesJob [async]
                            → DerivativeService#create_derivatives
                            → index_adapter.save(parent work)  [Solr]
```
