## Premailer CHANGELOG

### Version 1.10.1

 * Depends on css_parser 1.4.10.
 * Drops wrong destructive sorting of attributes (`css_parser` already does it correctly)
 * Replace obsolete `URI` calls with `Addressable::URI`.
 * Drop last semicolon from attributes.
 * Update tests.
