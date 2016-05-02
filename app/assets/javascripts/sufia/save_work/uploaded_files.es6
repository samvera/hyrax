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

  get hasNewFiles() {
    // In a future release hasFiles will include files already on the work plus new files,
    // but hasNewFiles() will include only the files added in this browser window.
    return this.hasFiles
  }
}
