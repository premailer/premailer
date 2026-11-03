# Benchmark

`bundle exec rake benchmark` times premailer on the general-purpose emails in `emails/` and prints, for each one, the median time and the objects allocated by `Premailer.new` (reading the HTML and its stylesheets), then by `#to_inline_css` and `#to_plain_text` on a premailer already built. A change that makes premailer faster should show up here; edge cases belong in the unit tests.

```
RUNS=20 ADAPTER=nokogiri EMAIL=foundation bundle exec rake benchmark
```

`RUNS` sets how many calls each median takes (20 by default), `ADAPTER` the adapter (`nokogiri` by default, also `nokogiri_fast` or `nokogumbo`), and `EMAIL` a pattern the file names must match. Compare two versions by running it on each, on the same machine, a few times: timings move by a few percent from one run to the next, allocations don't.

## Emails

All MIT-licensed, see `emails/LICENSES.md`:

- `foundation-*.html`: the 11 sample templates of [Foundation for Emails](https://github.com/foundation/foundation-emails/tree/7a37ae4cad4f97068f8257ba92a67a261080e3c5/templates), compiled with [inky-rb](https://github.com/foundation/inky-rb) 1.4.2.1 into the boilerplate of its CSS guide, which links the 34 KB `foundation-emails.css` and adds the template's own `<style>`. Most of the inlining time goes here.
- `mailgun-*.html`: Mailgun's [transactional email templates](https://github.com/mailgun/transactional-email-templates/tree/e05e59e8c1e0fa7ffbacc7a165a609fd37c590b5/templates) (action, alert, billing), with a small `<style>` tag. Their markup is mostly inlined already, so they show the cost of a small email more than of inlining.
- `responsive-html-email-template.html`: Lee Munroe's [responsive HTML email template](https://github.com/leemunroe/responsive-html-email-template/blob/60b5b6ddf9600e4b7d7e1ef60e5a3a8f1e56e186/email.html), with its CSS in a `<style>` tag.
