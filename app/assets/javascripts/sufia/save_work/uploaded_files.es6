export class UploadedFiles {
  // Monitors the form and runs the callback if any files are added
  constructor(form, callback) {
    this.form = form
    $('#fileupload').bind('fileuploadcompleted', callback)
  }

  get hasFiles() {
    let fileField = this.form.find('input[name="uploaded_files[]"]')
    return fileField.size() > 0
  }
}
