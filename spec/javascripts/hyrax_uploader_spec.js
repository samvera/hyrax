describe("Hyrax.Uploader", function() {
  var Uploader = require('hyrax/uploader').Uploader;
  var sentRequests;
  var RealXMLHttpRequest = window.XMLHttpRequest;

  // A minimal XHR stand-in capturing Hyrax.Uploader's content uploads and
  // succeeding immediately.
  function MockXhr() {
    var self = this;
    this.upload = { addEventListener: function() {} };
    this.headers = {};
    this.status = 200;
    this.responseText = '{}';
    this.listeners = {};
    this.open = function(method, url) { self.method = method; self.url = url; };
    this.setRequestHeader = function(name, value) { self.headers[name] = value; };
    this.addEventListener = function(name, handler) { self.listeners[name] = handler; };
    this.abort = function() { if (self.listeners.abort) { self.listeners.abort(); } };
    this.send = function(body) {
      self.body = body;
      sentRequests.push(self);
      setTimeout(function() { self.listeners.load(); }, 0);
    };
  }

  function stubCreateResponse(id) {
    return Promise.resolve({
      ok: true,
      json: function() {
        return Promise.resolve({ files: [{ id: id, name: 'test.txt', deleteUrl: '/uploads/' + id }] });
      }
    });
  }

  function widgetFixture() {
    setFixtures(
      '<div id="hyrax-uploader-fixture">' +
      '  <table><tbody class="files"></tbody></table>' +
      '</div>'
    );
    // <template> content is inert; jasmine-jquery fixtures tolerate it
    var template = document.createElement('template');
    template.id = 'hyrax-upload-row';
    template.innerHTML =
      '<tr class="template-download">' +
      '  <td><p class="name" data-upload-name></p>' +
      '      <strong class="error" data-upload-error></strong>' +
      '      <input type="hidden" data-upload-id-input data-upload-field-name="uploaded_files[]" value="">' +
      '      <div class="progress"><div class="progress-bar" data-upload-progress></div></div></td>' +
      '  <td><span class="size" data-upload-size></span></td>' +
      '  <td><button type="button" data-upload-cancel></button>' +
      '      <button type="button" data-upload-delete hidden></button></td>' +
      '</tr>';
    document.getElementById('hyrax-uploader-fixture').appendChild(template);
    return document.getElementById('hyrax-uploader-fixture');
  }

  beforeEach(function() {
    sentRequests = [];
    window.XMLHttpRequest = MockXhr;
  });

  afterEach(function() {
    window.XMLHttpRequest = RealXMLHttpRequest;
  });

  it("registers the filename, uploads the bytes, and fills the row", function(done) {
    spyOn(window, 'fetch').and.callFake(function() { return stubCreateResponse(42); });
    var element = widgetFixture();
    var uploader = new Uploader(element, { maxChunkSize: 1000000 });

    element.addEventListener('hyrax:uploads:completed', function() {
      // pre-create posted the filename
      expect(window.fetch).toHaveBeenCalled();

      // one unchunked content upload carrying the record id
      expect(sentRequests.length).toEqual(1);
      expect(sentRequests[0].headers['Content-Range']).toBeUndefined();
      expect(sentRequests[0].body.get('id')).toEqual('42');

      // the row's hidden input now carries the staged file id
      var input = element.querySelector('input[name="uploaded_files[]"]');
      expect(input.value).toEqual('42');
      done();
    });

    uploader.addFiles([new File(['hello world'], 'test.txt')]);
  });

  it("splits large files into sequential Content-Range chunks", function(done) {
    spyOn(window, 'fetch').and.callFake(function() { return stubCreateResponse(7); });
    var element = widgetFixture();
    var uploader = new Uploader(element, { maxChunkSize: 10 });

    element.addEventListener('hyrax:uploads:completed', function() {
      expect(sentRequests.length).toEqual(3);
      expect(sentRequests[0].headers['Content-Range']).toEqual('bytes 0-9/25');
      expect(sentRequests[1].headers['Content-Range']).toEqual('bytes 10-19/25');
      expect(sentRequests[2].headers['Content-Range']).toEqual('bytes 20-24/25');
      done();
    });

    uploader.addFiles([new File(['1234567890123456789012345'], 'chunky.bin')]);
  });

  it("fires the legacy jQuery event names for the save work gate", function(done) {
    spyOn(window, 'fetch').and.callFake(function() { return stubCreateResponse(9); });
    var element = widgetFixture();
    var events = [];
    ['fileuploadstart', 'fileuploadadded', 'fileuploadcompleted', 'fileuploadstop'].forEach(function(name) {
      $(element).on(name, function() { events.push(name); });
    });
    var uploader = new Uploader(element, { maxChunkSize: 1000000 });

    $(element).on('fileuploadstop', function() {
      expect(events).toEqual(['fileuploadadded', 'fileuploadstart', 'fileuploadcompleted', 'fileuploadstop']);
      done();
    });

    uploader.addFiles([new File(['hello'], 'events.txt')]);
  });

  it("rejects files over maxFileSize with an error row and no requests", function() {
    spyOn(window, 'fetch');
    var element = widgetFixture();
    var uploader = new Uploader(element, { maxFileSize: 3 });

    uploader.addFiles([new File(['way too big'], 'big.txt')]);

    expect(window.fetch).not.toHaveBeenCalled();
    expect(element.querySelector('[data-upload-error]').textContent).not.toEqual('');
    var input = element.querySelector('input[name="uploaded_files[]"]');
    expect(input).toBeNull();
  });
});
