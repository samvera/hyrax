# Migrating original files from disk to S3

Without an S3 storage adapter, Valkyrie writes original files to the disk adapter (`storage/files` by default) as `disk://` identifiers. That directory often ends up on a shared or network volume (NFS, EFS, a SAN, a mounted block device), which can cost far more per GB than object storage, and which has to be sized, backed up and shared between every app and worker process. This guide moves new and existing originals to S3 (or an S3-compatible service such as MinIO) so they stop living on that volume.

Only originals move. Derivatives, uploads and similar stay on the shared storage directories.

## Requirements

- Originals are on a plain `Valkyrie::Storage::Disk` adapter (`disk://` ids), registered as `:disk`. If it is registered under another name, set `Hyrax::S3Migration::SourceStorage.adapter_name = :that_name`. Apps on a versioned disk adapter (`versiondisk://` ids, which `rails generate hyrax:install` sets up) or on Fedora are not supported: they keep file versions and deletion markers that a copy to S3 would lose. The tasks stop with a clear message in that case.
- The destination is a [valkyrie-shrine](https://github.com/samvera/valkyrie-shrine) S3 adapter registered as `:repository_s3` (step 2).

## 1. Create the bucket

Use a private bucket with versioning on and public access blocked. Putting each client or deployment in its own bucket keeps access, lifecycle and cost accounting separate. Place it close to the app servers rather than to end users: the app reads files from the bucket and streams them to users, so distance between the app and the bucket adds latency and, on some providers, transfer cost.

## 2. Register the S3 adapter and make it the default

The app needs a Valkyrie storage adapter registered as `:repository_s3` (the generated `config/initializers/1_valkyrie.rb` has a commented example using the `REPOSITORY_S3_*` variables) and set as `Valkyrie.config.storage_adapter` so new files go there. Give the app read/write/delete and list access to the bucket, either through the credentials your platform provides (instance role, workload identity, environment credentials) or through the adapter's key options. Restart every process that writes files (web and background workers), and clear caches (including any IIIF/derivative caches).

New files now get `shrine://` identifiers. Existing files keep working from disk until migrated.

## 3. Migrate existing files

`hyrax:migrate:files_to_s3` enqueues one background job per file set (`MigrateFilesToS3Job` lists the disk files, `MigrateFileSetToS3Job` moves each one), so speed scales with the number of job workers. Each job uploads the file, reads it back from S3 and compares its SHA-256 with the disk file, and only then switches the identifier; on a mismatch the upload is removed and the file stays on disk. The S3 adapter also verifies each upload on its own, comparing an MD5 of the source file with the object's ETag, which reads the source file one more time. Before uploading, the disk file is also checked against the checksum Hyrax recorded when the file was characterized (an MD5, optionally written as `urn:md5:`, `urn:sha1:` or `urn:sha256:`); a mismatch is reported as `suspect` and the file is not migrated. Transient errors retry. The disk copy is never touched, and the task can be re-run safely (migrated files are skipped).

Start with a dry run, which runs inline and prints what it would do. It reads every file to check checksums, so it takes a while on large repositories:

```bash
DRY_RUN=true bundle exec rake hyrax:migrate:files_to_s3
```

Then a small real batch, run inline so you can read the output, followed by the full run, which enqueues jobs:

```bash
INLINE=true LIMIT=5 bundle exec rake hyrax:migrate:files_to_s3
bundle exec rake hyrax:migrate:files_to_s3
```

Run these wherever you normally run rake tasks against the app (a console on an app host, a container, an orchestrator job).

Things to know when running at scale:

- Set `S3_MIGRATION_QUEUE` to run the jobs on a dedicated queue (your workers must be listening to it) so ingest and derivative jobs are not starved.
- Per-file results are logged as `[S3Migration] <file set id> <status>`.
- File sets are not re-indexed: the migration changes only where the bytes are stored, so the search index (including extracted full text) is left exactly as it was. Re-indexing would also re-read every file from S3 and re-run text extraction.
- File sets with no original file (for example empty file sets left by an import) are reported as `NO_ORIGINAL` and skipped; nothing is moved or deleted for them.
- Long inline runs, reports and audits print a progress line every 500 items with the elapsed time and rate. Change the interval with `PROGRESS_EVERY=<n>`, or set it to `0` to turn it off.
- Every migrated file also gets a manifest object in the bucket (see step 5).
- The live site reads from the same storage while this runs, so start with few workers and watch the storage's throughput and latency.

### Applications that partition one repository (for example multitenant apps)

The tasks work on the repository the app is currently pointed at, so run them once per partition with whatever mechanism your app has for that. If one bucket serves several partitions, set `Hyrax::S3Migration.scope_provider` to a callable returning a label for the current partition (for example in an initializer); manifest entries are then stored per label, so the quarantine and rollback steps only touch the current partition's files.

## 4. Verify

- Audit what is in S3 (read-only; checks the object exists, the recorded size and the stored checksum): `bundle exec rake hyrax:migrate:verify_s3_files`. Expect `Problems: 0`.
- A newly created work's original has a `shrine://` identifier.
- Old and new works still display their files (viewer/IIIF, downloads) after clearing caches.
- Thumbnails are unaffected (they are derivatives).
- A re-run of the migration reports nothing left to migrate.
