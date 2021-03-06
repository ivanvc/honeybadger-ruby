# Troubleshooting

Common issues/workarounds are documented here. If you don't find a solution to
your problem here or in our [support
documentation](http://docs.honeybadger.io/), email support@honeybadger.io and
one or all of our helpful founders will assist you!

## How to enable verbose logging

Troubleshooting any of these issues will be much easier if you can see what's
going on with Honeybadger when your app starts. To enable verbose debug logging,
run your app with the `HONEYBADGER_DEBUG=true` environment variable or add the
following to your *honeybadger.yml* file:

```yml
debug: true
```

By default Honeybadger will log to the default Rails logger or STDOUT outside of
Rails. When debugging it can be helpful to have a dedicated log file for
Honeybadger. To enable one, set the
`HONEYBADGER_LOGGING_PATH=log/honeybadger.log` environment variable or add the
following to your *honeybadger.yml* file:

```yml
logging:
  path: 'log/honeybadger.log'
```

## Common Issues

### My errors aren't being reported

Error reporting may be disabled for several reasons:

#### Honeybadger is not configured

Honeybadger requires at minimum the `api_key` option to be set. If Honeybadger
is unable to start due to invalid configuration, you should see something like
the following in your logs:

```
** [Honeybadger] Unable to start Honeybadger -- api_key is missing or invalid. level=2 pid=18195
```

#### Honeybadger is not started

We currently initialize Rails and Sinatra apps automatically. If you use either
of those frameworks and are not receiving error reports, then you probably have
a different issue and should skip this section. For all other frameworks (or
plain ol' Ruby), `Honeybadger.start()` must be called manually.

To verify that Honeybadger is not started, [enable debug
logging](#how-to-enable-verbose-logging) and then start your app; if Honeybadger
was initialized, you should see something in the log output.

```
** [Honeybadger] Starting Honeybadger version 2.1.0 level=1 pid=18077
```

If you don't get any logs prefixed with "** [Honeybadger]", then you can start
Honeybadger manually like this:

```ruby
honeybadger_config = Honeybadger::Config.new
Honeybadger.start(honeybadger_config)
```

## Sidekiq/Resque/ActiveJob/etc.

- See [Honeybadger is not started](#honeybadger-is-not-started)

### Is the error ignored by default?

Honeybadger ignores [this list of
exceptions](https://github.com/honeybadger-io/honeybadger-ruby/blob/master/lib/honeybadger/config/defaults.rb#L7)
by default. It may be surprising that `ActiveRecord::RecordNotFound` is on that
list; that's because in a Rails controller that error class is treated as a 404
not-found and handled internally (and thus we shouldn't report it).  Support for
Sidekiq and friends was added later and inherited the default. We would like to
provide alternate defaults for job processors in the future, but for now you can
provide your own list of ignored class names if you want to change this
behavior:

```
HONEYBADGER_EXCEPTIONS_IGNORE_ONLY=Error,ClassNames,Here bundle exec sidekiq
```
