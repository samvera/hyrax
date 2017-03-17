import { Registry } from './registry'
import { UserControls } from './user_controls'
import { GroupControls } from './group_controls'

export default class PermissionsControl {
  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {String} template_id the identifier of the template for the added elements
   */
  constructor(element, template_id) {
    if (element.length === 0) {
      return
    }
    this.element = element

    this.registry = new Registry(this.element, this.object_name(), template_id)
    this.user_controls = new UserControls(this.element, this.registry)
    this.group_controls = new GroupControls(this.element, this.registry)
  }

  // retrieve object_name the name of the object to create
  object_name() {
    return this.element.data('param-key')
  }
}
