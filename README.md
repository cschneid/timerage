# Timerage

Simple refinement to make Time Ranges work a little.

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

class MyClass
  using Timerage

  # Step over these two times in 10 second steps
  def my_method(time1, time2)
    (time1..time2).step(10) { |time| puts time}
  end
end
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
