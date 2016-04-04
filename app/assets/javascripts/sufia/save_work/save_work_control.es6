import { RequiredFields } from './required_fields'
import { ChecklistItem } from './checklist_item'
import { UploadedFiles } from './uploaded_files'

/**
 * Polyfill String.prototype.startsWith()
 */
if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(searchString, position){
      position = position || 0;
      return this.substr(position, searchString.length) === searchString;
  };
}

export class SaveWorkControl {
  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selctor for the save panel
   */
  constructor(element) {
    if (element.size() == 0) {
      return
    }
    this.element = element
    this.form = element.closest('form')
  }

  // Is the form for a new object (vs edit an exisiting object)
  get isNew() {
    return this.form.attr('id').startsWith('new')
  }

  /*
   * Call this when the form has been rendered
   */
  activate() {
    if (!this.form) {
      return
    }
    this.requiredFields = new RequiredFields(this.form, () => this.formChanged())
    this.uploads = new UploadedFiles(this.form, () => this.formChanged())

    this.saveButton = this.element.find(':submit')

    this.requiredMetadata = new ChecklistItem(this.element.find('#required-metadata'))
    this.requiredFiles = new ChecklistItem(this.element.find('#required-files'))
    this.formChanged()
  }

  formChanged() {
    let valid = this.validateMetadata() && this.validateFiles()
    this.saveButton.prop("disabled", !valid);
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.check()
      return true
    }
    this.requiredMetadata.uncheck()
    return false
  }

  // sets the files indicator to complete/incomplete
  validateFiles() {
    if (!this.isNew || this.uploads.hasFiles) {
      this.requiredFiles.check()
      return true
    }
    this.requiredFiles.uncheck()
    return false
  }
}

