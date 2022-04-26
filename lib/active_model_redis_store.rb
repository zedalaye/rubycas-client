require 'redis'
require 'redis-store'
require 'redis-activesupport'
require 'redis-actionpack'
require 'action_dispatch/middleware/session/redis_store'
require 'active_support/cache/redis_store'
require 'redis-rack'
require 'rack/session/abstract/id'

module ActionDispatch
  module Session
    # A session store that uses an ActiveSupport::Cache::Store to store the sessions. This store is most useful
    # if you don't store critical data in your sessions and you don't need them to live for extended periods
    # of time.
    #
    # ==== Options
    # * <tt>cache</tt>         - The cache to use. If it is not specified, <tt>Rails.cache</tt> will be used.
    # * <tt>expire_after</tt>  - The length of time a session will be stored before automatically expiring.
    #   By default, the <tt>:expires_in</tt> option of the cache is used.
    class ActiveModelRedisStore < ActionDispatch::Session::RedisStore
      SERVICE_TICKET = "service_ticket".freeze

      def write_session(req, sid, new_session, options = {})
        session = find_session(req, sid)[1]
        unless session.nil?
          # Copy session_id and service_ticket into the session_data
          %w(sid service_ticket).each { |key| new_session[key] = session[key] if session[key] }
        end
        super(req, sid, new_session, options)
      end

      # The service ticket is also being stored in Redis in the form -
      # service_ticket => session_id
      # session_id => {session_data}
      # Need to ensure that when a session is being destroyed - we also clean up the service-ticket
      # related data prior to letting the session be destroyed.
      def delete_session(req, session_id, options = {})
        session = find_session(req, session_id)[1]
        if session.present?
          if session.key?(SERVICE_TICKET)
            service_ticket_session = find_session(req, ::Rack::Session::SessionId.new(session[SERVICE_TICKET]))[1]
            if service_ticket_session.present?
              begin
                super(req, service_ticket_session, options)
              rescue => e
                CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#delete_session: #{e}")
                raise if raise_errors?
              end
            else
              CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#delete_session: [SESSION #{session_id}] Service ticket key is nil.")
            end
            super(req, session_id, options)
          else
            CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#delete_session: the retrieved session for session_id #{session_id} is nil")
          end
        end
      end
    end
  end
end
