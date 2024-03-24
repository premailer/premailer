# Premailer README [![CI](https://github.com/premailer/premailer/actions/workflows/actions.yml/badge.svg)](https://github.com/premailer/premailer/actions/workflows/actions.yml) [![Gem Version](https://badge.fury.io/rb/premailer.svg)](https://badge.fury.io/rb/premailer)

## What is this?

For the best HTML e-mail delivery results, CSS should be inline. This is a
huge pain and a simple newsletter becomes un-managable very quickly. This
gem is a solution.

* CSS styles are converted to inline style attributes
  - Checks `style` and `link[rel=stylesheet]` tags and preserves existing inline attributes
* Relative paths are converted to absolute paths
  - Checks links in `href`, `src` and CSS `url('')`
* CSS properties are checked against e-mail client capabilities
  - Based on the Email Standards Project's guides
* A [plain text version](#plain-text-version) is created (optional)

## Installation

```bash
gem install premailer
```

## Example

```ruby
require 'premailer'

premailer = Premailer.new('http://example.com/myfile.html', warn_level: Premailer::Warnings::SAFE)

# Write the plain-text output (must come before to_inline_css)
File.write "output.txt", premailer.to_plain_text

# Write the HTML output
File.write "output.html", premailer.to_inline_css

# Output any CSS warnings
premailer.warnings.each do |w|
  puts "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
end
```

## Adapters

1. nokogiri (default)
2. nokogiri_fast (20x speed, more memory)
3. nokogumbo

(hpricot adapter removed, use `~>1.9.0` version if you need it)

Picking an adapter:

```ruby
Premailer::Adapter.use = :nokogiri_fast
```

## Ruby Compatibility

See .github/workflows/actions.yml for which ruby versions are tested. JRuby support is close, contributors are welcome.

## Premailer-specific CSS

Premailer looks for a few CSS attributes that make working with tables a bit easier.

| CSS Attribute | Availability |
| ------------- | ------------ |
| -premailer-width | Available on `table`, `th` and `td` elements |
| -premailer-height | Available on `table`, `tr`, `th` and `td` elements |
| -premailer-cellpadding | Available on `table` elements |
| -premailer-cellspacing | Available on `table` elements |
| -premailer-align | Available on `table` elements |
| data-premailer="ignore" | Available on `link` and `style` elements. Premailer will ignore these elements entirely. |

Each of these CSS declarations will be copied to appropriate element's attribute.

For example

```css
table { -premailer-cellspacing: 5; -premailer-width: 500; }
```

will result in

```html
<table cellspacing='5' width='500'>
```

## Plain text version

Premailer can generate a plain text version of your HTML. Links and images will be inlined.

For example

```html
<a href="https://example.com" >
  <img src="https://github.com/premailer.png" alt="Premailer Logo" />
</a>
```

will become

```text
Premailer Logo ( https://example.com )
```

To ignore/omit a section of HTML content from the plain text version, wrap it with the following comments.

```html
<!-- start text/html -->
<p>This will be omitted from the plain text version.</p>
<p>
  This is extremely helpful for <strong>removing email headers and footers</strong>
  that aren't needed in the text version.
</p>
<!-- end text/html -->
```

## Configuration options

For example:
```ruby
Premailer.new(
  html, # html as string
  with_html_string: true,
  drop_unmergeable_css_rules: true
)
```

[available options](https://premailer.github.io/premailer/Premailer.html#initialize-instance_method)


## Contributions

Contributions are most welcome.
Premailer was rotting away in a private SVN repository for too long and could use some TLC.
Fork and patch to your heart's content.
Please don't increment the version numbers.

A few areas that are particularly in need of love:

* Improved test coverage
* Move un-repeated background images defined in CSS for Outlook

## Credits and code

Thanks to [all the wonderful contributors](https://github.com/premailer/premailer/contributors) for their updates.

Thanks to [Greenhood + Company](http://www.greenhood.com/) for sponsoring some of the 1.5.6 updates,
and to [Campaign Monitor](https://www.campaignmonitor.com/) for supporting the web interface.

The source code can be found on [GitHub](https://github.com/premailer/premailer).

Copyright by Alex Dunae (dunae.ca, e-mail 'code' at the same domain), 2007-2017.  See [LICENSE.md](https://github.com/premailer/premailer/blob/master/LICENSE.md) for license details.
