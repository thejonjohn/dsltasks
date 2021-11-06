# Dsltasks

## Overview

`dsltasks` enables rapid development of hierarchical ruby-based DSLs. See the example usage below to get an idea of some of the capabilities.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dsltasks'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dsltasks

## Silly Example Usage

`Gemfile`:
```
source 'https://rubygems.org'

gem 'dsltasks'
```

`example.rb`:
```ruby
require 'dsltasks'

DSLTasks::start(main: ARGV.shift, libs: ['money-dsl.rb'])
```

`money-dsl.rb`:
```ruby
require 'date'

task :account do |name, block|

  transactions = []

  task :date do |str, block|
    d = Date.parse(str)

    task :transaction do |opts|
      amount = opts[:amount]
      payee  = opts[:payee]
      transactions.push({
        amount: amount,
        payee: payee,
        date: d
      })
    end

    instance_exec(&block)

  end

  instance_exec(&block)

  puts "Account: #{name}"
  total = 0
  transactions.chunk {|t| t[:date]}
              .sort {|e1, e2| e1[0] <=> e2[0]}
              .each do |d, ts|
    puts "Date: #{d}"
    ts.each do |t|
      print "  #{t[:payee]}".ljust(40)
      puts "%.2f" % t[:amount] # this is just silly example code; don't really use floating point to represent currency!
      total += t[:amount]
    end
    puts
  end
  puts "Total: %.2f" % total
end
```

`checking.rb`:
```ruby
account "checking" do

  date "2020-1-7" do
    transaction payee: "Initial deposit", amount: 1000
  end

  date "2020-1-17" do
    transaction payee: "Amazon.com", amount: -59.78
    transaction payee: "Dr. Fillgoods", amount: -15
  end

  date "2020-1-25" do
    transaction payee: "Bob", amount: 70
  end
end
```

Then run `bundle install` followed by `bundle exec ruby example.rb checking.rb` to get the following output:

```
Account: checking
Date: 2020-01-07
  Initial deposit                       1000.00

Date: 2020-01-17
  Amazon.com                            -59.78
  Dr. Fillgoods                         -15.00

Date: 2020-01-25
  Bob                                   70.00

Total: 995.22
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thejonjohn/dsltasks.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

