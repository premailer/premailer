# Premailer README [![Build Status](https://travis-ci.org/premailer/premailer.png?branch=master)](https://travis-ci.org/premailer/premailer)

## What is this?

For the best HTML e-mail delivery results, CSS should be inline. This is a 
huge pain and a simple newsletter becomes un-managable very quickly. This 
script is my solution.

* CSS styles are converted to inline style attributes
  - Checks `style` and `link[rel=stylesheet]` tags and preserves existing inline attributes
* Relative paths are converted to absolute paths
  - Checks links in `href`, `src` and CSS `url('')`
* CSS properties are checked against e-mail client capabilities
  - Based on the Email Standards Project's guides
* A plain text version is created (optional)

## Premailer 2.0 is coming

I'm looking for input on a version 2.0 update to Premailer. Please visit the [Premailer 2.0 Planning Page](https://github.com/premailer/premailer/wiki/New-Premailer-2.0-Planning) and give me your feedback.

## Installation

Install the Premailer gem from RubyGems.

```bash
gem install premailer
```

or add it to your `Gemfile` and run `bundle`.

## Example

```ruby
require 'rubygems' # optional for Ruby 1.9 or above.
require 'premailer'

premailer = Premailer.new('http://example.com/myfile.html', :warn_level => Premailer::Warnings::SAFE)

# Write the HTML output
File.open("output.html", "w") do |fout|
  fout.puts premailer.to_inline_css
end

# Write the plain-text output
File.open("output.txt", "w") do |fout|
  fout.puts premailer.to_plain_text
end

# Output any CSS warnings
premailer.warnings.each do |w|
  puts "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
end
```

## Ruby Compatibility

Premailer is tested on Ruby 1.8.7, Ruby 1.9.2, Ruby 1.9.3, and Ruby 2.x.0 . It also works on REE. JRuby support is close; contributors are welcome.  Checkout the latest build status on the [Travis CI dashboard](http://travis-ci.org/#!/premailer/premailer).

## Premailer-specific CSS

Premailer looks for a few CSS attributes that make working with tables a bit easier.

| CSS Attribute | Availability |
| ------------- | ------------ |
| -premailer-width | Available on `table`, `th` and `td` elements |
| -premailer-height | Available on `table`, `tr`, `th` and `td` elements |
| -premailer-cellpadding | Available on `table` elements |
| -premailer-cellspacing | Available on `table` elements |
| data-premailer="ignore" | Available on `style` elements. Premailer will ignore these elements entirely. |

Each of these CSS declarations will be copied to appropriate element's attribute.

For example

```css
table { -premailer-cellspacing: 5; -premailer-width: 500; }
```

will result in 

```html
<table cellspacing='5' width='500'>
```

## Contributions

Contributions are most welcome.  Premailer was rotting away in a private SVN repository for too long and could use some TLC.  Fork and patch to your heart's content.  Please don't increment the version numbers, though.

A few areas that are particularly in need of love:

* Improved test coverage
* Move un-repeated background images defined in CSS for Outlook

## Credits and code

Thanks to [all the wonderful contributors](https://github.com/alexdunae/premailer/contributors) for their updates.

Thanks to [Greenhood + Company](http://www.greenhood.com/) for sponsoring some of the 1.5.6 updates,
and to [Campaign Monitor](http://www.campaignmonitor.com) for supporting the web interface.

The web interface can be found at [premailer.dialect.ca](http://premailer.dialect.ca).

The source code can be found on [GitHub](https://github.com/alexdunae/premailer).

Copyright by Alex Dunae (dunae.ca, e-mail 'code' at the same domain), 2007-2012.  See [LICENSE.md](https://github.com/alexdunae/premailer/blob/master/LICENSE.md) for license details.

