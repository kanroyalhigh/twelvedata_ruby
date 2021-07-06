# TwelvedataRuby

TwelvedataRuby

TwelvedataRuby is a Ruby library that provides convenient ways to access the Twelve Data API to get stock, forex, crypto, and other financial data. First, a free API Key is required and it might be requested [here](https://twelvedata.com/pricing). Visit their [API's full documentation](https://twelvedata.com/doc)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'twelvedata_ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install twelvedata_ruby

## Usage

First, you need to obtain a personal free API Key from Twelve Data which might be requested from this link https://twelvedata.com/apikey. After obtaining the key, you need to either:

1. Assign it to an ENV variable called `TWELVEDATA_API_KEY`. This is the preferred so your key won't be exposed. Or,
2. You can pass along the API key during client requests. By default, the api key that is passed along will be the one to use and will just fallback to the ENV variable name `TWELVEDATA_API_KEY`.

TwelvedataRuby offers several entry points to access any endpoint of the API.

```
require "twelvedata_ruby"

client = TwelvedataRuby::Client.new

request = client.price(symbol: "IBM")

response = request.fetch

```
or fetch it directly from the client instance

```
response = client.price(symbol: "IBM").fetch
```

or, you can actually just chain them all and do it in one line

```
response = TwelvedataRuby::Client.new.price(symbol: "IBM").fetch

```

As you may have noticed, the Twelve Data API endpoint `price` behaves like an instance method and its required and optional parameters behave like its method arguments. This is true to the rest of the endpoints. Treat it like an instance method with method arg keys that are the same with the API documentation.

```
resp1 = client.time_series(symbol: 'IBM', interval: '1day')
resp2 = client.time_series(symbol: 'IBM,AAPL', interval: '1hour', format: :csv, filename: 'ibm-apple-time-series.csv')
resp3 = client.quote(symbol: "USD/JPY")

...
``

You can also access the endpoint via a `Request` instance

```
response = TwelvedataRuby::Request.new(endpoint_name: :quote, params: {symbol: "GOOG"}).fetch
```

or, instantiates several request objects first, then send the requests in one go. The library will fire up the multiple requests in parallel.

```
req1 = TwelvedataRuby::Request.new(endpoint_name: :quote, params: {symbol: "MSFT,USD/JPY,BTC/USD"})
req2 = TwelvedataRuby::Request.new(endpoint_name: :eod, params: {symbol: "GOOG"})
req3 = TwelvedataRuby::Request.new(endpoint_name: :time_series, params: {symbol: "F", interval: "1hour"})

responses = TwelvedataRuby::Client.request([req1, req2, req3])

```

Just be careful as you might hit your daily limit in one go if you're just using a free api key.


TODO: still a lot of features to document and write more rspec examples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/twelvedata_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/twelvedata_ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TwelvedataRuby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/twelvedata_ruby/blob/master/CODE_OF_CONDUCT.md).


# Notice

This is not an offical Twelve Data ruby library and the author of this gem is not affiliated with Twelve Data in any way, shape or form. Twelve Data APIs and data are Copyright © 2020 Twelve Data Pte. Ltd
