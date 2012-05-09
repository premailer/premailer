# Premailer README

## What is this?

For the best HTML e-mail delivery results, CSS should be inline. This is a 
huge pain and a simple newsletter becomes un-managable very quickly. This 
script is my solution.

* CSS styles are converted to inline style attributes
  - Checks <tt>style</tt> and <tt>link[rel=stylesheet]</tt> tags and preserves existing inline attributes
* Relative paths are converted to absolute paths
  - Checks links in <tt>href</tt>, <tt>src</tt> and CSS <tt>url('')</tt>
* CSS properties are checked against e-mail client capabilities
  - Based on the Email Standards Project's guides
* A plain text version is created (optional)

## Premailer 2.0 is coming

I'm looking for input on a version 2.0 update to Premailer.  PLease visit the [Premailer 2.0 Planning Page](https://github.com/alexdunae/premailer/wiki/Premailer-2.0-Planning) and give me your feedback.

## Installation

Download the Premailer gem from RubyGems.

```bash
gem install premailer
```

## Example

```ruby
premailer = Premailer.new('http://example.com/myfile.html', :warn_level => Premailer::Warnings::SAFE)

# Write the HTML output
fout = File.open("output.html", "w")
fout.puts premailer.to_inline_css
fout.close

# Write the plain-text output
fout = File.open("ouput.txt", "w")
fout.puts premailer.to_plain_text
fout.close

# Output any CSS warnings
premailer.warnings.each do |w|
  puts "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
end
```

## Ruby Compatibility

Premailer is tested on Ruby 1.8.7, Ruby 1.9.2 and Ruby 1.9.3 (preview 1). It also works on REE. JRuby support is close; contributors are welcome.  Checkout the latest build status on the [Travis CI dashboard](http://travis-ci.org/#!/alexdunae/premailer).

## Premailer-specific CSS

Premailer looks for a few CSS attributes that make working with tables a bit easier.
<dl>
  <dt>-premailer-width</dt>
    <dd>Available on <tt>table</tt>, <tt>th</tt> and <tt>td</tt> elements</dd>
  <dt>-premailer-height</dt>
    <dd>Available on <tt>table</tt>, <tt>tr</tt>, <tt>th</tt> and <tt>td</tt> elements</dd>
  <dt>-premailer-cellpadding</dt>
    <dd>Available on <tt>table</tt> elements</dd>
  <dt>-premailer-cellspacing</dt>
    <dd>Available on <tt>table</tt> elements</dd>
</dl>

Each of these CSS declarations will be copied to appropriate element's attribute.

For example

```css
table { -premailer-cellspacing: 5; -premailer-width: 500;}
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

