# RubyCAS-Client Changelog

## 3.2.0
* Other
  * Supports Redis in newer rack versions.

## 3.1.1
* Other
  * Use controller.request in `active_record_ticket_store` instead of controller to set `.env` value for rack. Rails 5.1+ change.

## 3.1.0
* New Functionality
  * Now supports Redis as an option for configuring the session storage client.
  * There is no impact to existing working of Memcached.

## 3.0.7
* Other
  * Fix log issue where session lookups were being performed with null keys.

## 3.0.6
* Other
  * Only use session object in Session.session_destroy if its available

## 3.0.5
* Other
  * Use controller.request instead of controller to set `.env` value for rack. Rails 5.1+ change.

## 3.0.4
* Other
  * Cast session.id to string as with Rails 5.2+ it is of type Rack::Session::SessionId.

## 3.0.3
* Other
  * support rails 5/rack 2.0. Memcached session support introduced in 3.0.2 updated to work with Rails 5.

## 3.0.2
* Other
  * Stray initializer for memcached sessions leftover in consuming app moved into gem.
  * Using `render plain:` instead of deprecated `render text:` to support rails 5.

## 3.0.1
* Bug fixes
  * Use the version declared in `lib/casclient/version.rb` instead of hardcoding it in the gemspec file.

## 3.0.0
* New functionality
  * Sessions can now be stored in Memcached.

## 2.3.13
* New functionality
  * Add the ability to set any top-level session attribute for the fake user.
  * Add method returning the activity tracker update interval from the CAS extra attributes.

## 2.3.12
* New functionality
  * Add before method to lib/casclient/frameworks/rails/filter.rb
    in order to make rubycas-client compatible with rails 4

## 2.3.11
* New functionality
  * Add dice-bag template

## 2.3.10
* New functionality
  * Add support for Rails 4 applications

## 2.3.9

* Other
  * ci against lots more ruby versions - see .travis.yml and the travis
    status page

## 2.3.9rc1

* Bug Fixes
  * Fixed issue that caused Single Sign Out to fail (@bryanlarsen and @soorajb)
  * Fixed issue in Filter#unauthorized! (@mscottford)
  * Fixed #38, boolean values are now preserved in extra attribute yaml
    parsing

* New functionality
  * Tweak the CasProxyCallbackController so it can be used with
    rubycas-client-rails in Rails 3 (@bryanlarsen)
  * Add support for calling the CAS Server through an HTTP proxy (@shevaun)
  * Add support for specifying the service url to be added to the
    logout url (@dyson)
  * add support for extra attributes as xml attributes (@bhenderson)
  * Add :raw mode to extra attribute parsing

* Other
  * Made writing and running rspec tests much easier
  * Added tests for Ticket Stores
  * Official support for jruby 1.6

## 2.3.8

* Bug Fixes
  * Fix some undesired behavior when parsing extra attributes as JSON
    * Simple attributes (that aren't JSON Objects) stay strings
    * We don't fallback to the YAML parser if JSON parsing fails

## 2.3.7

* Bug Fixes
  * Fixed bug in how service_urls with query parameters are handled
  * Fixed issue with setting correct temp directory under Rails 3.1

## 2.3.6

* Bug Fixes
  * Don't attempt to store single sign out information if sessions
    aren't enabled for this request. Fixes a problem were we were
    blowing up trying to modify a frozen session

## 2.3.5

* Bug Fixes
  * read_service_url will no longer include POST parameters on the
    service url

## 2.3.3

* Bug Fixes
  * Removed a puts that didn't get cleaned up
  * Fix a bug with parsing extra attributes caused by a strange edge
    case in active_support

## 2.3.1

* New Functionality
  * Add configuration option to expect complex extra attributes to be encoded
    in json instead of yaml
  * Split out storage mechanism for single sign out and proxy ticket storage so
    that it is modular

* Changes to existing functionality
  * Change gem building from hoe to jeweler
  * expect extra attributes to be nested under a cas:attributes elemenet to
    improve compatibility with other extra attribute implementations
  * Unauthorized requests to URLs ending in .json now show an JSON formatted
    response

* Bug Fixes
  * Fixed bug introduced by upstream patch that broke proxy ticket validation
    when using extra attributes
  * Fixed bug where extra attributes key was set on the session with a null
    value when faking with no extra attributes

## 2.2.1

* Removed a 3rd party patch to the logging mechanism that broke the client under
  some circumstances. Ouch. 2.2.0 should never have made it through QA.

## 2.2.0

RubyCAS-Client is now licensed under the MIT License.
See http://www.opensource.org/licenses/mit-license.php

* New functionality:
  * Added config parameter force_ssl_verification (self explanatory) [Roberto Klein]
  * Added explicit SingleSigoutFilter for Rails (convenient?) [Adam Elliot]
  * Added support for faking out the filter; useful when testing. See
    http://github.com/gunark/rubycas-client/commit/1eb10cc285d59193eede3d4406f95cad9db9d93a
    [Brian Hogan]

* Changes to existing functionality:
  * Unauthorized requests to URLs ending in .xml now show an XML formatted
    response (<errors><error>#{failure_message}</error></errors>) [Roberto Klein]
  * Accepts HTTPFound (302) as a successful response from the CAS server (in
    addition to HTTPSuccess (2xx) [taryneast]

* Bug fixes:
  * Got rid of warnings if @valid is not initialized in Responses [jamesarosen]
  * Fixed warning when setting the logger [jamesarosen]
  * Client should no longer crap out when using CAS v1 and extra_attributes is
    empty [jorahood]


## 2.1.0

* New functionality:
  * Added an adapter for the Merb framework. Thanks to Andrew O'Brien and
    Antono Vasiljev.
  * Implemented single-sign-out functionality. The client will now intercept
    single-sign-out requests and deal with them appropriately if the
    :enable_single_sign_out config option is set to true. This is currently
    disabled by default. (Currently this is only implemented for the Rails
    adapter)
  * Added logout method to Rails adapter to simplify the logout process. The
    logout method resets the local Rails session and redirects to the CAS
    logout page.
  * Added login_url method to the Rails filter. This will return the login
    URL for the current controller; useful when you want to show a "Login"
    link in a gatewayed page for an unauthenticated user.
  * Added cas_server_is_up? method to the client, as requested in issue #5.
  * Extra user attributes are now automatically unserialized if the incoming data
    is in YAML format.

* Changes to existing functionality:
  * The 'service' parameter in the logout method has been renamed to
    'destination' to better match the behaviour of other CAS clients. So for
    example, when you call logout_url("http://foo.example"), the method will
    now return "https://cas.example?destination#https%3A%2F%2Ffoo.example"
    instead of the old "https://cas.example?service#https%3A%2F%2Ffoo.example".
    RubyCAS-Server has been modified to deal with this as of version 0.6.0.
  * We now accept HTTP responses from the CAS server with status code 422 since
    RubyCAS-Server 0.7.0+ generates these in response to requests that are
    processable but contain invalid CAS data (for example an invalid service
    ticket).
  * Some behind-the-scenes changes to the way previous authentication info is
    reused by the Rails filter in subsequent requests (see the note below
    in the 2.0.1 release). From the user's and integrator's point of view
    there shouldn't be any obvious difference from 2.0.1.
  * Redirection loop interception: The client now logs a warning message when it
    believes that it is stuck in a redirection loop with the CAS server. If more
    than three of these redirects occur within one second, the client will
    redirect back to the login page with renew#1, forcing the user to try
    authenticating again.
  * Somewhat better handling and logging of errors resulting from CAS server
    connection/response problems.

* Bug Fixes:
  * Fixed bug where the the service/destination parameter in the logout url
    would sometimes retain the 'ticket' value. The ticket is now automatically
    stripped from the logout url.
  * The client will no longer attempt to retrieve a PGT for an IOU that had
    already been previously retrieved. [yipdw1]

* Misc:
  * Added complete CAS client integration examples for Rails and Merb
    applications under /examples.

## 2.0.1

* The Rails filter no longer by default redirects to the CAS server on
  every request. This restores the behaviour of RubyCAS-Client 1.x.
  In other words, if a session[:cas_user] value exists, the filter
  will assume that the user is authenticated without going through the
  CAS server. This behaviour can be disabled (so that a CAS re-check is
  done on every request) by setting the 'authenticate_on_every_request'
  option to true. See the "Re-authenticating on every request" section
  in the README.txt for details.

## 2.0.0

* COMPLETE RE-WRITE OF THE ENTIRE CLIENT FROM THE GROUND UP. Oh yes.
* Core client has been abstracted out of the Rails adapter. It should now
  be possible to use the client in other frameworks (e.g. Camping).
* Configuration syntax has completely changed. In other words, your old
  rubycas-client-1.x configuration will no longer work. See the README
  for details.
* Added support for reading extra attributes from the CAS response (i.e. in
  addition to just the username). However currently this is somewhat useless
  since RubyCAS-Server does not yet provide a method for adding extra
  attributes to the responses it generates.

------------------------------------------------------------------------------

## 1.1.0

* Fixed serious bug having to do with logouts. You can now end the
  CAS session on the client-side (i.e. force the client to re-authenticate)
  by setting session[:casfilteruser] # nil.
* Added new GatewayFilter. This is identical to the normal Filter but
  has the gateway option set to true by default. This should make
  using the gateway option easier.
* The CAS::Filter methods are now properly documented.
* Simplified guess_service produces better URLs when redirecting to the CAS
  server for authentication and the service URL is not explicitly specified.
  [delagoya]
* The correct method for overriding the service URL for the client is now
  properly documented. You should use service_url#, as server_name# no longer
  works and instead generates a warning message.
* logout_url() now takes an additional 'service' parameter. If specified, this
  URL will be passed on to the CAS server as part of the logout URL.

## 1.0.0

* RubyCAS-Client has matured to the point where it is probably safe to
  take it out of beta and release version 1.0.
* Non-SSL CAS URLs will now work. This may be useful for demo purposes,
  but certainly shouldn't be used in production. The client automatically
  disables SSL if the CAS URL starts with http (rather than https). [rubywmq]

## 0.12.0

* Prior to redirecting to the CAS login page, the client now stores the
  current service URI in a session variable. This value is used to
  validate the service ticket after the user comes back from the CAS
  server's login page. This should address issues where redirection
  from the CAS server resulted in a slightly different URI from the original
  one used prior to login redirection (for example due to variations in the
  way routing rules are applied by the server).
* The client now handles malformed CAS server responses more gracefully.
  This makes debugging a malfunctioning CAS server somewhat easier.
* When receiving a proxy-granting ticket, the cas_proxy_callback_controller
  can now take a parameter called 'pgt' (which is what ought to be used
  according to the published CAS spec) or 'pgtId' (which is what the JA-SIG
  CAS server uses).
* Logging has been somewhat quieted down. Many messages that were previously
  logged as INFO are now logged as DEBUG.

## 0.11.0

* Added this changelog to advise users of major changes to the library.
* Large chunks of the library have been re-written. Beware of the possibility
  of new bugs (although the re-write was meant to fix a whole slew of existing
  bugs, so you're almost certainly better off upgrading).
* service and targetService parameters in requests are now properly URI-encoded,
  so the filter should behave properly when your service has query parameters.
  Thanks sakazuki for pointing out the problem.
* You can now force the CAS client to re-authenticate itself with the CAS server
  (i.e. override the authentication stored in the session) by providing a new
  service ticket in the URI. In other words, the client will authenticate with
  CAS if: a) you have a 'ticket' parameter in the URI, and there is currently no
  authentication info in the session, or b) you have a 'ticket' parameter in the
  URI and this ticket is different than the ticket that was used to authenticat
  the existing session. This is especially useful when you are using CAS proxying,
  since it allows you to force re-authentication in proxied applications (for
  example, when the user has logged out and a new user has logged in in the parent
  proxy-granting application).
* If your service URI has a 'ticket' parameter, it will now be automatically
  removed when passing the service as a parameter in any CAS request. This is
  done because at least some CAS servers will happily accept a service URI with
  a 'ticket' parameter, which will result in a URI with  multiple 'ticket'
  parameters once you are redirected back to CAS (and that in turn can result
  in an endless redirection loop).
* Logging has been greatly improved, which should make debugging your CAS
  installation much easier. Look for the logs under log/cas_client_RAILS_ENV.log
* When you install RubyCAS-Client as a Rails plugin, it will now by default
  use a custom logger. You can change this by explicitly setting your own
  logger in your environment.rb, or by modifying the plugin's init.rb.
* CasProxyCallbackController no longer checks to make sure that the incoming
  request is secure. The check is impossible since the secure header is not
  passed on by at least some reverse proxies (like Pound), and if you are using
  the callback controller then you are almost certainly also using a reverse
  proxy.
* Cleaned up and updated documentation, fixed some example code.
