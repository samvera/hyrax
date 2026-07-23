// Hyrax.Uploader — dependency-free replacement for the vendored blueimp
// jQuery-File-Upload widget.
//
// Speaks Hyrax's two-step staged upload protocol:
//
//   1. POST /uploads with `files[]=<filename>` pre-creates a
//      Hyrax::UploadedFile record and returns its id;
//   2. the file's bytes are POSTed with that `id`, split into sequential
//      chunks with a Content-Range header when the file exceeds
//      `maxChunkSize` — keeping each request small enough for proxies that
//      cap request size (e.g. Cloudflare's 100 MB limit);
//   3. completed uploads render a row from a server-side <template>
//      element whose hidden input (uploaded_files[], banner_files[], ...)
//      carries the staged file id when the enclosing form is submitted;
//   4. removing a row DELETEs the staged record.
//
// Events are fired both as DOM CustomEvents (`hyrax:uploads:added`, etc.)
// and, when jQuery is present, as the blueimp-era jQuery events
// (`fileuploadadded`, `fileuploadcompleted`, `fileuploaddestroyed`,
// `fileuploadfail`) that hyrax/save_work/uploaded_files.es6 listens to, so
// the Save gate keeps working unchanged.
//
// Configuration comes from `Hyrax.config.uploader` (limitConcurrentUploads,
// maxNumberOfFiles, maxFileSize), data attributes on the widget element
// (`data-row-template`), and per-call options.

const DEFAULTS = {
  url: '/uploads/',
  maxChunkSize: 10000000, // 10 MB chunks, as the blueimp widget used
  limitConcurrentUploads: 6,
  maxNumberOfFiles: 100,
  maxFileSize: 500 * 1024 * 1024,
  acceptFileTypes: null,        // e.g. /(\.|\/)(gif|jpe?g|png)$/i
  rowTemplate: 'hyrax-upload-row',
  messages: {
    maxFileSize: 'File is too large',
    minFileSize: 'File is too small',
    acceptFileTypes: 'File type not allowed',
    maxNumberOfFiles: 'Maximum number of files exceeded',
    uploadFailed: 'Upload failed'
  }
};

const csrfToken = function() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.content : null;
};

const formatFileSize = function(bytes) {
  if (typeof bytes !== 'number') { return ''; }
  if (bytes >= 1000000000) { return (bytes / 1000000000).toFixed(2) + ' GB'; }
  if (bytes >= 1000000) { return (bytes / 1000000).toFixed(2) + ' MB'; }
  return (bytes / 1000).toFixed(2) + ' KB';
};

// One file's upload lifecycle: pre-create, chunked (or single-shot)
// content upload, cancel/removal.
class Upload {
  constructor(uploader, file) {
    this.uploader = uploader;
    this.file = file;
    this.id = null;
    this.deleteUrl = null;
    this.row = null;
    this.xhr = null;
    this.canceled = false;
    this.loadedBase = 0; // bytes confirmed from completed chunks
    this.loaded = 0;
  }

  start() {
    return this.createRecord()
      .then(() => this.sendContent())
      .then((response) => this.complete(response))
      .catch((error) => this.fail(error));
  }

  // step 1: register the filename, receiving the staged record id
  createRecord() {
    const params = new URLSearchParams();
    params.append('files[]', this.file.name);

    return fetch(this.uploader.options.url, {
      method: 'POST',
      body: params,
      headers: { 'X-CSRF-Token': csrfToken(), 'Accept': 'application/json' },
      credentials: 'same-origin'
    }).then((response) => {
      if (!response.ok) { throw new Error('HTTP ' + response.status); }
      return response.json();
    }).then((json) => {
      const record = json.files[0];
      this.id = record.id;
      this.deleteUrl = record.deleteUrl;
    });
  }

  // step 2: the bytes — sequential Content-Range chunks for large files
  sendContent() {
    const size = this.file.size;
    const chunkSize = this.uploader.options.maxChunkSize;
    if (!chunkSize || size <= chunkSize) { return this.sendChunk(0, size, false); }

    let sequence = Promise.resolve();
    for (let start = 0; start < size; start += chunkSize) {
      const end = Math.min(start + chunkSize, size);
      sequence = sequence.then((response) => {
        this.loadedBase = start;
        return this.sendChunk(start, end, true).then((chunkResponse) => chunkResponse || response);
      });
    }
    return sequence;
  }

  sendChunk(start, end, ranged) {
    if (this.canceled) { return Promise.reject(new Error('canceled')); }

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      this.xhr = xhr;
      const blob = (start === 0 && end === this.file.size) ? this.file : this.file.slice(start, end);
      const data = new FormData();
      data.append('id', this.id);
      data.append('files[]', blob, this.file.name);

      xhr.open('POST', this.uploader.options.url);
      xhr.setRequestHeader('X-CSRF-Token', csrfToken());
      xhr.setRequestHeader('Accept', 'application/json');
      if (ranged) {
        xhr.setRequestHeader('Content-Range', 'bytes ' + start + '-' + (end - 1) + '/' + this.file.size);
      }

      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          this.loaded = this.loadedBase + Math.min(event.loaded, end - start);
          this.uploader.progressChanged(this);
        }
      });
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          this.loaded = this.loadedBase + (end - start);
          this.uploader.progressChanged(this);
          resolve(xhr.responseText);
        } else {
          reject(new Error('HTTP ' + xhr.status));
        }
      });
      xhr.addEventListener('error', () => reject(new Error('network error')));
      xhr.addEventListener('abort', () => reject(new Error('canceled')));
      xhr.send(data);
    });
  }

  complete(responseText) {
    let record = { id: this.id, name: this.file.name, size: this.file.size, deleteUrl: this.deleteUrl };
    try {
      const parsed = JSON.parse(responseText);
      if (parsed && parsed.files && parsed.files[0]) { record = parsed.files[0]; }
    } catch (e) { /* keep locally-known attributes */ }
    this.uploader.uploadCompleted(this, record);
  }

  fail(error) {
    if (this.canceled || (error && error.message === 'canceled')) {
      this.uploader.uploadCanceled(this);
    } else {
      this.uploader.uploadFailed(this, error);
    }
  }

  cancel() {
    this.canceled = true;
    if (this.xhr) { this.xhr.abort(); }
    this.destroyRecord();
  }

  destroyRecord() {
    if (!this.deleteUrl) { return Promise.resolve(); }
    return fetch(this.deleteUrl, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken() },
      credentials: 'same-origin'
    });
  }
}

class Uploader {
  // @param element [HTMLElement] the widget container (e.g. #fileupload)
  // @param options [Object] overrides merged over Hyrax.config.uploader
  constructor(element, options) {
    this.element = element;
    const configured = (window.Hyrax && window.Hyrax.config && window.Hyrax.config.uploader) || {};
    this.options = Object.assign({}, DEFAULTS, configured, options || {});
    this.options.messages = Object.assign({}, DEFAULTS.messages, configured.messages || {}, (options || {}).messages || {});
    if (element.dataset.rowTemplate) { this.options.rowTemplate = element.dataset.rowTemplate; }

    this.uploads = [];
    this.queue = [];
    this.active = 0;

    element.hyraxUploader = this;
    this.bindInputs();
    this.bindDropzone();
    this.bindButtons();

    // widgets whose file input is not `multiple` (versioning, collection
    // banner) hold a single staged file: a new upload replaces the row
    if (this.options.singleFile === undefined) {
      const inputs = element.querySelectorAll('input[type="file"][name="files[]"]');
      this.options.singleFile = inputs.length > 0 &&
        !Array.prototype.some.call(inputs, (input) => input.hasAttribute('multiple'));
    }
    // elements to clear when a new upload begins (e.g. the currently
    // attached banner and its banner_unchanged input); from
    // data-upload-clear="<selector>"
    this.clearSelector = element.dataset.uploadClear;
  }

  // ---- wiring -----------------------------------------------------------

  bindInputs() {
    this.element.querySelectorAll('input[type="file"][name="files[]"]').forEach((input) => {
      input.addEventListener('change', () => {
        let files = Array.prototype.slice.call(input.files);
        if (files.length > 1 && !input.hasAttribute('multiple')) { files = files.slice(0, 1); }
        this.addFiles(files);
        input.value = '';
      });
    });
  }

  bindDropzone() {
    const dropzone = this.element.querySelector('.dropzone');
    if (!dropzone) { return; }

    ['dragover', 'dragenter'].forEach((name) => {
      dropzone.addEventListener(name, (event) => {
        event.preventDefault();
        dropzone.classList.add('hover');
      });
    });
    dropzone.addEventListener('dragleave', () => dropzone.classList.remove('hover'));
    dropzone.addEventListener('drop', (event) => {
      event.preventDefault();
      dropzone.classList.remove('hover');
      if (event.dataTransfer && event.dataTransfer.files) {
        this.addFiles(Array.prototype.slice.call(event.dataTransfer.files));
      }
    });
    // highlight the dropzone while anything drags over the page
    document.addEventListener('dragover', () => {
      dropzone.classList.add('in');
      if (this._dropTimeout) { clearTimeout(this._dropTimeout); }
      this._dropTimeout = setTimeout(() => dropzone.classList.remove('in', 'hover'), 100);
    });
  }

  bindButtons() {
    // widget-level cancel (e.g. the work form's reset button)
    this.element.querySelectorAll('button.cancel').forEach((button) => {
      if (button.closest('tr, .template-download')) { return; }
      button.addEventListener('click', () => this.cancelAll());
    });
  }

  // ---- public API --------------------------------------------------------

  // switch which <template> renders completed rows (used by the batch form)
  setRowTemplate(templateId) {
    this.options.rowTemplate = templateId;
  }

  addFiles(files) {
    files.forEach((file) => this.add(file));
  }

  add(file) {
    if (this.options.singleFile) { this.replaceExisting(); }
    const error = this.validate(file);
    const upload = new Upload(this, file);
    upload.row = this.buildRow(upload);
    this.uploads.push(upload);
    this.fire('added', { files: [file] });

    if (error) {
      this.uploadFailed(upload, new Error(error));
      return;
    }
    this.queue.push(upload);
    this.pump();
  }

  cancelAll() {
    this.queue = [];
    this.uploads.forEach((upload) => {
      if (!upload.finished) { upload.cancel(); }
    });
  }

  // single-file widgets: drop any current upload/row (and, on the first
  // upload, any server-rendered current-file markup) before a new one
  replaceExisting() {
    this.queue = [];
    this.uploads.forEach((upload) => {
      if (!upload.finished) {
        upload.cancel();
      } else if (upload.row) {
        this.detachRow(upload);
      }
    });
    if (this.clearSelector) {
      this.element.querySelectorAll(this.clearSelector).forEach((node) => node.parentNode.removeChild(node));
    }
  }

  // ---- queue -------------------------------------------------------------

  pump() {
    while (this.active < this.options.limitConcurrentUploads && this.queue.length > 0) {
      const upload = this.queue.shift();
      if (this.active === 0 && !this.batchRunning) {
        this.batchRunning = true;
        this.fire('start', {});
      }
      this.active += 1;
      upload.start().then(() => {
        this.active -= 1;
        this.pump();
      });
    }
    if (this.batchRunning && this.active === 0 && this.queue.length === 0) {
      this.batchRunning = false;
      this.fire('stop', {});
    }
  }

  // ---- validation --------------------------------------------------------

  validate(file) {
    const messages = this.options.messages;
    if (this.options.maxNumberOfFiles &&
        this.completedOrActiveCount() >= this.options.maxNumberOfFiles) { return messages.maxNumberOfFiles; }
    if (this.options.maxFileSize && file.size > this.options.maxFileSize) { return messages.maxFileSize; }
    if (this.options.acceptFileTypes &&
        !(this.options.acceptFileTypes.test(file.type) || this.options.acceptFileTypes.test(file.name))) {
      return messages.acceptFileTypes;
    }
    return null;
  }

  completedOrActiveCount() {
    return this.uploads.filter((upload) => !upload.failed).length;
  }

  // ---- row rendering -----------------------------------------------------

  template() {
    const template = document.getElementById(this.options.rowTemplate);
    if (!template) { throw new Error('Missing upload row template #' + this.options.rowTemplate); }
    return template;
  }

  filesContainer() {
    return this.element.querySelector('.files');
  }

  buildRow(upload) {
    const fragment = this.template().content.cloneNode(true);
    const row = fragment.firstElementChild;

    this.fill(row, '[data-upload-name]', upload.file.name);
    this.fill(row, '[data-upload-size]', formatFileSize(upload.file.size));

    const cancel = row.querySelector('[data-upload-cancel]');
    if (cancel) { cancel.addEventListener('click', () => this.removeUpload(upload)); }

    this.filesContainer().appendChild(fragment);
    return row;
  }

  fill(row, selector, value) {
    const node = row.querySelector(selector);
    if (node) { node.textContent = value; }
  }

  progressChanged(upload) {
    if (upload.row) {
      const bar = upload.row.querySelector('[data-upload-progress]');
      if (bar) { bar.style.width = Math.round((upload.loaded / upload.file.size) * 100) + '%'; }
    }
    this.updateGlobalProgress();
  }

  updateGlobalProgress() {
    const container = this.element.querySelector('.fileupload-progress');
    if (!container) { return; }
    const bar = container.querySelector('.progress-bar');
    const pending = this.uploads.filter((upload) => !upload.failed && !upload.canceled);
    const total = pending.reduce((sum, upload) => sum + upload.file.size, 0);
    const loaded = pending.reduce((sum, upload) => sum + (upload.finished ? upload.file.size : upload.loaded), 0);

    const finished = pending.every((upload) => upload.finished);
    container.classList.toggle('in', !finished);
    if (bar && total > 0) { bar.style.width = Math.round((loaded / total) * 100) + '%'; }
  }

  // finalize a row: reveal the hidden id input, wire deletion
  uploadCompleted(upload, record) {
    upload.finished = true;
    const row = upload.row;

    // form inputs are authored nameless (their name is carried in
    // data-upload-field-name) so an in-flight row neither satisfies the
    // required-files gate nor submits partial values; name them now
    row.querySelectorAll('[data-upload-field-name]').forEach((input) => {
      input.name = input.dataset.uploadFieldName;
    });
    const idInput = row.querySelector('input[data-upload-id-input]');
    if (idInput) { idInput.value = record.id; }
    // batch/versioning templates parameterize input names with {{id}}
    row.querySelectorAll('[name*="{{id}}"], [id*="{{id}}"], [for*="{{id}}"], [data-file-id*="{{id}}"]').forEach((node) => {
      ['name', 'id', 'for', 'data-file-id'].forEach((attribute) => {
        const value = node.getAttribute(attribute);
        if (value && value.indexOf('{{id}}') !== -1) { node.setAttribute(attribute, value.split('{{id}}').join(record.id)); }
      });
    });

    // inputs that default to the filename (batch per-file title)
    row.querySelectorAll('[data-upload-name-value]').forEach((input) => {
      if (!input.value) { input.value = record.name || upload.file.name; }
    });

    const progress = row.querySelector('[data-upload-progress]');
    if (progress) {
      progress.style.width = '100%';
      const wrapper = progress.closest('.progress');
      if (wrapper) { wrapper.classList.add('upload-complete'); }
    }

    const cancel = row.querySelector('[data-upload-cancel]');
    if (cancel) { cancel.hidden = true; }
    const remove = row.querySelector('[data-upload-delete]');
    if (remove) {
      remove.hidden = false;
      remove.setAttribute('data-url', record.deleteUrl || upload.deleteUrl || '');
      remove.addEventListener('click', () => this.removeUpload(upload));
    }

    this.updateGlobalProgress();
    this.fire('completed', { files: [record], result: { files: [record] } });
  }

  uploadFailed(upload, error) {
    upload.failed = true;
    upload.finished = true;
    if (upload.row) {
      this.fill(upload.row, '[data-upload-error]', (error && error.message) || this.options.messages.uploadFailed);
      const cancel = upload.row.querySelector('[data-upload-cancel]');
      if (cancel) { cancel.hidden = false; }
    }
    this.updateGlobalProgress();
    this.fire('fail', { files: [upload.file], error: error });
  }

  uploadCanceled(upload) {
    upload.canceled = true;
    upload.finished = true;
    this.detachRow(upload);
    this.updateGlobalProgress();
    this.fire('fail', { files: [upload.file], canceled: true });
  }

  // remove a pending or completed upload: abort/delete server side, drop
  // the row (and its hidden input) client side
  removeUpload(upload) {
    if (!upload.finished) {
      upload.cancel(); // fires 'fail' via the abort path
      return;
    }
    upload.destroyRecord();
    this.detachRow(upload);
    this.fire('destroyed', { files: [{ id: upload.id }] });
  }

  detachRow(upload) {
    if (upload.row && upload.row.parentNode) { upload.row.parentNode.removeChild(upload.row); }
    upload.row = null;
  }

  // ---- events ------------------------------------------------------------

  // Fires hyrax:uploads:<name> as a CustomEvent and the legacy blueimp
  // jQuery event name (fileuploadadded, ...) for existing listeners.
  fire(name, data) {
    this.element.dispatchEvent(new CustomEvent('hyrax:uploads:' + name, { detail: data, bubbles: true }));
    if (window.jQuery) { window.jQuery(this.element).trigger('fileupload' + name, data); }
  }
}

Uploader.formatFileSize = formatFileSize;

export { Uploader, formatFileSize }
