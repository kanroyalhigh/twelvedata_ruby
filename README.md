# TwelvedataRuby

[![Gem Version](https://badge.fury.io/rb/twelvedata_ruby.svg)](https://badge.fury.io/rb/twelvedata_ruby)

TwelvedataRuby is a Ruby library that exposes some convenient ways to access Twelve Data API to get information on stock, forex, crypto, and other financial market data. In order to do so, a free API key is required which can be easily requested [here](https://twelvedata.com/pricing). Visit their [API's full documentation](https://twelvedata.com/doc)

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

The preferred way to include the Twelve Data API key in the request payload is to assign it to an ENVIRONMENT variable which your Ruby application can fetch if none was explicitly assigned. The default ENVIRONMENTt variable name is `TWELVEDATA_API_KEY` but you can configure this to any other value  using the `#apikey_env_var_name=` setter method.

To get hold of the singleton `TwelvedataRuby::Client.instance`, you can directly used that inherited instance method from the mixed in `Singleton` module or thru the gem's module helper class method:

```ruby
require "twelvedata_ruby"
client = TwelvedataRuby.client
```

By not passing anything to the options method parameters, the `client` instance attributes will have default values. Though you can still set different values to the attributes through their helper setter methods:

```ruby
client.apikey = "twelvedata-apikey"
client.apikey_env_var_name = "the_environment_variable_name" # the helper getter method will upcase the value
client.connect_timeout = 300 # can also accept "300"
```

or simply set them all at once:

```ruby
require "twelvedata_ruby"
client = TwelvedataRuby.client(apikey: "twelvedata-apikey", connect_timeout: 300)
# or client = TwelvedataRuby.client(apikey_env_var_name: "the_environment_variable_name", connect_timeout: 300)
```

The default values though are sufficient already.

Getting any type of financial data then from the API, simply invoke any valid endpoint name to the client instance. For example, to fetch some data for `GOOG` stock symbol using quote, timeseries, price, and etd API endpoints:

```ruby
# 1. response content-type will be :csv
client.quote(symbol: "GOOG", format: :csv)
# 2. assigns custom attachment name
client.timeseries(symbol: "GOOG", interval: "1hour", format: :csv, filename: "google_timeseries_1hour.csv")
# 3. the content-type format will be :json
client.price(symbol: "GOOG")
# 4. the passed apikey is the used in the request payload
client.etd(symbol: "GOOG", apikey: "overrides-whatever-is-the-current-apikey")
# 5. an example of invocation which the API will respond with 401 error code
client.etd(symbol: "GOOG", apikey: "invalid-api-key")
# 6. still exactly the same object with client
TwelvedataRuby.client.api_usage
# 7. an invalid request wherein the required query parameter :interval is missing
TwelvedataRuby.client.timeseries(symbol: "GOOG")
# 8. an invalid request because it contains an invalid parameter
client.price(symbol: "GOOG", invalid_parameter: "value")
# 9. invoking a non-existing API endpoint will cause a NoMethodError exception
client.price(symbol: "GOOG", invalid_parameter: "value")
```

All of the invocations possible return instance value is one of the following:
- `TwelvedataRuby::Response` instance object which `#error` instance getter method can return a nil or kind of `TwelvedataRuby::ResponseError` instance if the API, or the API web server responded with some errors. #5 is an example which the API response will have status error with 401 code. `TwelvedataRuby::Response` resolves this into `TwelvedataRuby::UnauthorizedResponseError` instance.
- `TwelvedataRuby::ResponseError` instance object itself when some error occurred that's not coming from the API
- a Hash instance which has an `:errors` key that contains instances of kind `TwelvedataRuby::EndpointError`. This is an invalid request scenario which the #7, #8, and #9 examples. No actual API request was sent in this scenario.

On first invocation of a valid endpoint name, a `TwelvedataRuby::Client` instance method of the same name is dynamically defined. So in effect, ideally, there can be a one-to-one mapping of all the API endpoints with their respective parameters constraints. Please visit their excellent API documentation to know more of the endpoint details here https://twelvedata.com/doc. Or if you're in a hurry, you can list the endpoints definitions:

```ruby
TwelvedataRuby::Endpoint.definitions
```

Another way of fetching data from API endpoints is by building a valid `TwelvedataRuby::Request` instance, then invoke `#fetch` on this instance. The possible return values are the same with the above examples.

```ruby
quote_req = TwelvedataRuby::Request.new(:quote, symbol: "IBM")
quote_resp = quote_req.fetch
timeseries_req = TwelvedataRuby::Request.new(:quote, symbol: "IBM", interval: "1hour", format: :csv)
timeseries_resp = timeseries_req.fetch
etd_req = TwelvedataRuby::Request.new(:etd, symbol: "GOOG")
etd_resp = etd_req.fetch
# or just simply chain
price_resp = TwelvedataRuby::Request.new(:price, symbol: "GOOG").fetch
```

An advantage of building a valid request instance first then invoke the `#fetch` on it is you actually have an option to not send the request one by one BUT rather send them to the API server all at once simultaneously (might be in parallel). Like so taking the above examples' request instance objects, send them all simultaneously

```ruby
# returns a 3 element array of Response objects
resp_objects_array = TwelvedataRuby::Client.request(quote_req, timeseries_req, etd_req)
```

Be caution that the above example, depending on the number request objects sent and how large the responses, hitting the daily limit is likely possible. But then again if you have several api keys you might be able to supply each request object with its own apikey. :)


The data from a successful API request can be access from `Response#parsed_body`. If request format is `:json` then it will be a `Hash` instance

```ruby
TwelvedataRuby.client.quote(symbol: "GOOG").parsed_body
=>
{:symbol=>"GOOG",
 :name=>"Alphabet Inc",
 :exchange=>"NASDAQ",
 :currency=>"USD",
 :datetime=>"2021-07-15",
 :open=>"2650.00000",
 :high=>"2651.89990",
 :low=>"2611.95996",
 :close=>"2625.33008",
 :volume=>"828300",
 :previous_close=>"2641.64990",
 :change=>"-16.31982",
 :percent_change=>"-0.61779",
 :average_volume=>"850344",
 :fifty_two_week=>{:low=>"1406.55005", :high=>"2659.91992", :low_change=>"1218.78003", :high_change=>"-34.58984", :low_change_percent=>"86.65031", :high_change_percent=>"-1.30041", :range=>"1406.550049 - 2659.919922"}}
```

Likewise, if the API request format is `:csv` then `Response#parsed_body` will be `CSV#Table` instance

```ruby
TwelvedataRuby.client.quote(symbol: "GOOG", format: :csv).parsed_body
=> #<CSV::Table mode:col_or_row row_count:2>
```

## Documentation
You can browse the source code [documentation](https://kanroyalhigh.github.io/twelvedata_ruby/doc/)
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/twelvedata_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/twelvedata_ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TwelvedataRuby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/twelvedata_ruby/blob/master/CODE_OF_CONDUCT.md).


# Notice

This is not an offical Twelve Data ruby library and the author of this gem is not affiliated with Twelve Data in any way, shape or form. Twelve Data APIs and data are Copyright © 2020 Twelve Data Pte. Ltd
