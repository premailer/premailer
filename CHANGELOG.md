## Premailer CHANGELOG

### Version 1.11.1
* Fix input encoding in nokogiri adapters.

### Version 1.11.0

* Support for HTML fragments rendering (without enforcing of doctype, head, body). See :html_fragment option.
* Depends on css_parser 1.6.0.

### Version 1.10.4

 * Exponential regexp in convert_to_text fixed.

### Version 1.10.3

 * Keep consecutive whitespaces.
 * Depends on css_parser 1.5.0.

### Version 1.10.2

 * Fix LoadError addressable with Addressable 2.3.8

### Version 1.10.1

 * Depends on css_parser 1.4.10.
 * Drops wrong destructive sorting of attributes (`css_parser` already does it correctly)
 * Replace obsolete `URI` calls with `Addressable::URI`.
 * Drop last semicolon from attributes.
 * Update tests.
