## Premailer CHANGELOG

### Unreleased

### Version 1.27.1
* Support and interpolate CSS variables from loaded stylesheets

### Version 1.27.0
* Support multiline inline styles [issue](https://github.com/premailer/premailer/issues/458)

### Version 1.26.0
* Bump css_parser to 1.19 to avoid deprecations

### Version 1.25.0
* Performance and frozen strings fixes

### Version 1.24.0
* Removes frozen string errors with RUBYOPT="--enable-frozen-string-literal"

### Version 1.23.0
* Drop Ruby 2.7 compatibility
* Require Nokogiri >= 1.16
* Add support for no-comma rgb() functions when `rgb_to_hex_attributes: true`

### Version 1.22.0
* Use rule_set_exceptions in for expand_shorthand!

### Version 1.21.0
* Use rule_set_exceptions in nokogiri_fast and nokogumbo adapters

### Version 1.20.0
* Catch errors during expand_shorthand and handle using rule_set_exceptions

### Version 1.19.0
* Conditionally set YAML loading arguments based on psych gem version

### Version 1.18.0
* Use new rule_set_exceptions in nokogiri adapter to swallow invalid css errors silently

### Version 1.17.0
* Support ignoring rule set exceptions from CSS Parser

### Version 1.16.0
* drop ruby 2.5 and 2.6
* change id generation from MD5 -> SHA-256

### Version 1.15.0
* improve a href parsing

### Version 1.14.3
* add existing license to gemspec

### Version 1.14.2
* fix greedy url() parsing

### Version 1.14.1
* Fix to converting inline html 100px to 100

### Version 1.14.0
* Convert inline html 100px to 100

### Version 1.13.1
* Replace deprecated File.exists? with File.exist? (fixes Ruby 2.8 deprecation warning)

### Version 1.13.0
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
