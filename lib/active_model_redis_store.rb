require 'action_dispatch/middleware/session/abstract_store'
require 'redis'
require 'redis-store'
require 'redis-activesupport'
require 'redis-actionpack'

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
    class ActiveModelRedisStore < ActiveSupport::Cache::RedisStore

      def set_session(env, sid, session_data, options = nil)
        expiry = get_expiry(env, options)
        if expiry
          redis.setex(prefixed(sid), expiry, encode(session_data))
        else
          redis.set(prefixed(sid), encode(session_data))
        end
        sid
      rescue Errno::ECONNREFUSED, Redis::CannotConnectError => e
        on_redis_down.call(e, env, sid) if on_redis_down
        false
      end
      alias write_session set_session

      # The service ticket is also being stored in Redis in the form -
      # service_ticket => session_id
      # session_id => {session_data}
      # Need to ensure that when a session is being destroyed - we also clean up the service-ticket
      # related data prior to letting the session be destroyed.
      def delete_matched(matcher, options = nil)
        if @pool.exist?(session_id)
          session = @pool.get(session_id)
          if session.present?
            if session.has_key?("service_ticket") && @pool.exist?(session["service_ticket"])
              begin
                @pool.delete(session["service_ticket"])
              rescue Errno::ECONNREFUSED
                CASClient::LoggerWrapper.new.warn("Session::RedisStore#delete_matched: #{$!.message}");
              end
            else
              message = session.has_key?('service_ticket') ? "Service ticket key present, @pool.exist?: #{@pool.exist?(session['service_ticket'])}" : "Service ticket key is nil."
              CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#destroy_session: [SESSION #{session_id}] #{message}");
            end
          else
            CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#destroy_session: the retrieved pool session for session_id #{session_id} is nil");
          end
        end
        super(env, session_id, options)
      end

      # # Patch Rack 2.0 changes that broke ActionDispatch.
      # alias_method :find_session, :get_session
      # alias_method :write_session, :set_session
      # alias_method :delete_session, :destroy_session

    end
  end
end

module ActiveSupport
  module Cache
    class RedisCacheStore
      # alias_method :get, :read_multi
      # alias_method :set, :write
    end
  end
end
