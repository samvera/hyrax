export class UploadedFiles {
  // Monitors the form and runs the callback when files are added
  constructor(form, callback) {
    this.form = form
    this.element = $('#fileupload')
    this.uploadsInProgress = 0
    this.element.on('fileuploadadded', (e, data) => {
      this.uploadsInProgress += 1
      callback(e, data)
    })
    this.element.on('fileuploadcompleted', (e, data) => {
      this.uploadsInProgress -= 1
      callback(e, data)
    })
    this.element.on('fileuploaddestroyed', callback)
  }

  get hasFileRequirement() {
    let fileRequirement = this.form.find('li#required-files')
    return fileRequirement.length > 0
  }

  get inProgress() {
    return this.uploadsInProgress > 0;
  }

  get hasFiles() {
    let fileField = this.form.find('input[name="uploaded_files[]"]')
    return fileField.length > 0
  }

  get hasNewFiles() {
    // In a future release hasFiles will include files already on the work plus new files,
    // but hasNewFiles() will include only the files added in this browser window.
    return this.hasFiles
  }
}
