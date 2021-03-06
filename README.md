# MonitRequestClient

Put Rails reqeust to rabbitmq to parse. I use golang to parse it and find our application problem.
But I want to use grpc to implement it in future(used it in golang in some project).
step by step, just wait.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'monit_request_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monit_request_client

## Usage

#### Config the yaml file(config/dashboard.yml)
```
connect:
  host: 127.0.0.1
  port: 5672
  username: guest
  password: guest
  vhost: /

queue_name: "tsx"
collect_data: true
path_prifex: /test
```

#### config/application.rb
```
require 'monit_request_client'

config.middleware.use  MonitRequestClient::Statistic
```

#### set current user
```
request.env["current_user_id"] = current_user.id
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/monit_request_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MonitRequestClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/monit_request_client/blob/master/CODE_OF_CONDUCT.md).
