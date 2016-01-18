# Timerage

Time Ranges that are actually useful.

## Installation

Add this line to your application's Gemfile:

    gem 'timerage'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timerage

## Usage

```ruby
require 'timerage'
```

### Coercion to Time (related) objects

``` ruby
a_time = Timerage("2016-01-18T22:25:37Z")
# => 2016-01-18 22:25:37 +0000

Timerage(a_time)
# => 2016-01-18 22:25:37 +0000

Timerage("2016-01-18T21:25:37+00:00/2016-01-18T22:25:37+00:00")
# => 2016-01-18 21:25:37 +0000...2016-01-18 22:25:37 +0000

interval = Timerage((a_time-3600)...a_time)
# => 2016-01-18 21:25:37 +0000...2016-01-18 22:25:37 +0000
```

### Stepping over a time inteval

```ruby
interval.step(30*60).map { |time| time }
# => [2016-01-18 21:25:37 +0000, 2016-01-18 21:55:37 +0000]
```

### Slicing a time interval

```ruby
interval.slice(30*60).map { |time| time }
# => [2016-01-18 21:25:37 UTC...2016-01-18 21:55:37 UTC, 2016-01-18 21:55:37 UTC...2016-01-18 22:25:37 UTC]
```

### ISO 8601 output

```ruby
interval.iso8601
# => "2016-01-18T21:25:37+00:00/2016-01-18T22:25:37+00:00"
```

### Comparisons

Supports most range/set comparisons

* `#overlap?`
* `#cover?`
* `#adjacent_to?`
* `#==`

### Concatenation

```ruby
interval + Timerage("2016-01-18T20:25:37+00:00/2016-01-18T21:25:37+00:00")
# => 2016-01-18 20:25:37 UTC..2016-01-18 22:25:37 UTC
```

### Duration

```ruby
interval.duration
# => 3600.0
```

## Gotchas

This doesn't fix the `#each` method to do anything useful, you still can't
blindly iterate over a range of time. You can use the `#step(seconds)` method
however, which makes more sense anyway.  (what does it even mean to iterate
over a time range? What is the next time after "now"? How many steps should we
take?)

## Contributing

1. Fork it ( http://github.com/cschneid/timerage/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
