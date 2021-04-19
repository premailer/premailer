## Premailer CHANGELOG

### Verion 1.14.3
* add existing license to gemspec

### Verion 1.14.2
* fix greedy url() parsing

### Verion 1.14.1
* Fix to converting inline html 100px to 100

### Verion 1.14.0
* Convert inline html 100px to 100

### Verion 1.13.1
* Replace deprecated File.exists? with File.exist? (fixes Ruby 2.8 deprecation warning)

### Verion 1.13.0
* Fix URI.open deprecation warnings

### Version 1.12.1
* Fix greedy script regex.

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
