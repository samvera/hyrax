import { RegistryEntry } from './registry_entry'
export class Registry {
  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {String} object_name the name of the object, for constructing form fields (e.g. 'generic_work')
   * @param {String} template_id the the identifier of the template for the added elements
   */
  constructor(element, object_name, template_id) {
    this.object_name = object_name
    this.template_id = template_id
    this.error = $('#permissions_error')
    this.errorMessage = $('#permissions_error_text')
    this.items = []

    // the remove button is only on preexisting grants
    $('.remove_perm').on('click', (evt) => this.removePermission(evt))

  }

  addError(message) {
    this.errorMessage.html(message);
    this.error.removeClass('hidden');
  }

  reset() {
    this.error.addClass('hidden');
  }

  removePermission(evt) {
     evt.preventDefault();
     let button = $(evt.target);
     let container = button.closest('tr');
     container.addClass('hidden'); // do not show the block
     this.addDestroyField(container, button.attr('data-index'));
     this.showPermissionNote();
  }

  addPermission(grant) {
    this.showPermissionNote()
    grant.index = this.nextIndex()
    this.items.push(new RegistryEntry(grant, this, $('#file_permissions'), this.template_id))
  }

  nextIndex() {
      return $('#file_permissions').parent().children().length - 1;
  }

  showPermissionNote() {
     $('#save_perm_note').removeClass('hidden');
  }

  addDestroyField(element, index) {
      $('<input>').attr({
          type: 'hidden',
          name: `${this.fieldPrefix(index)}[_destroy]`,
          value: 'true'
      }).appendTo(element);
  }

  fieldPrefix(counter) {
    return `${this.object_name}[permissions_attributes][${counter}]`
  }

  /*
   * make sure the permission being applied is not for a user/group
   * that already has a permission.
   */
  isPermissionDuplicate(user_or_group_name) {
    let s = `[${user_or_group_name}]`;
    var patt = new RegExp(this.preg_quote(s), 'gi');
    var perms_input = $(`input[name^='${this.object_name}[permissions]']`);
    var perms_sel = $(`select[name^='${this.object_name}[permissions]']`);
    var flag = 1;
    perms_input.each(function(index, form_input) {
	// if the name is already being used - return false (not valid)
	if (patt.test(form_input.name)) {
	  flag = 0;
	}
      });
    if (flag) {
      perms_sel.each(function(index, form_input) {
	// if the name is already being used - return false (not valid)
	if (patt.test(form_input.name)) {
	  flag = 0;
	}
      });
    }
    // putting a return false inside the each block
    // was not working.  Not sure why would seem better
    // rather than setting this flag var
    return (flag ? true : false);
  }

  // http://kevin.vanzonneveld.net
  // +   original by: booeyOH
  // +   improved by: Ates Goral (http://magnetiq.com)
  // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
  // +   bugfixed by: Onno Marsman
  // *     example 1: preg_quote("$40");
  // *     returns 1: '\$40'
  // *     example 2: preg_quote("*RRRING* Hello?");
  // *     returns 2: '\*RRRING\* Hello\?'
  // *     example 3: preg_quote("\\.+*?[^]$(){}=!<>|:");
  // *     returns 3: '\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:'

  preg_quote( str ) {
    return (str+'').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
  }
}
