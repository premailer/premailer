## Premailer CHANGELOG

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
