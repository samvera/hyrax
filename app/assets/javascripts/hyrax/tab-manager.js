function changeLocale(tab, tag) {
  $('#pager a').each(function(){
    if (tab) {
      href_value = this.href
      href_value = href_value.substring(0, href_value.indexOf('&'));
      href_value += '&tag=' + tab + '#' + tab;

      this.href = href_value;
    } else {
      href_value = this.href
      href_value = href_value.substring(0, href_value.indexOf('&'));
      href_value += '&tag=' + tag + '#' + tag;

      this.href = href_value;
    }
  })
}