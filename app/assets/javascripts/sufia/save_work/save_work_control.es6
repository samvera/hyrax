import { RequiredFields } from './required_fields'
import { ChecklistItem } from './checklist_item'

export class SaveWorkControl {
  constructor(element) {
    this.element = element
    this.form = element.closest('form')
    this.requiredFields = new RequiredFields(this.form, () => this.formChanged())
    this.requiredMetadata = new ChecklistItem(element.find('#required-metadata'))

    // Fire the change event after being loaded:
    this.formChanged()
  }

  formChanged() {
    this.validateMetadata()
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.check()
    } else {
      this.requiredMetadata.uncheck()
    }
  }
}

