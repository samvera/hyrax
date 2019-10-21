/**
 * Helper class for internationalization event handling
 */
export default class InternationalizationHelper {
  constructor() {
    this.addLangClickListener();
  }

  /**
   * Handle the event of selecting a new language from top bar, language select element.
   * This updates the html@lang attribute, which is important for screen readers
   */
  addLangClickListener() {
    $('#user_utility_links')
      .find('a.dropdown-item')
      .on('click', e => {
        let locale = e.target.dataset['locale'];
        if (!locale) {
          return;
        }
        $('html').attr('lang', locale);
      });
  }
}
