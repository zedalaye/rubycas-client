
require 'casclient/frameworks/rails/filter'
require 'redis'
require 'redis-store'
require 'redis-activesupport'
require 'redis-actionpack'

module CASClient
  module Tickets
    module Storage

      class ActiveModelRedisTicketStore < AbstractTicketStore

        def initialize(config={})
          RedisSessionStore.setup_client(config || {})
          RedisPgtiou.setup_client(config || {})
        end

        def store_service_session_lookup(st, controller)
          raise CASException, 'No service_ticket specified.' unless st
          raise CASException, 'No controller specified.' unless controller

          st = st.ticket if st.kind_of? ServiceTicket
          session_id = session_id_from_controller(controller)
          # Create a session in the DB if it hasn't already been created.
          RedisSessionStore.env = controller.request.env

          unless RedisSessionStore.find_by_session_id(session_id)
            log.info("RubyCAS Client did not find #{session_id} in the Session Store. Creating it now!")
            # We need to use .save instead of .create or the service_ticket won't be stored
            new_session = RedisSessionStore.new
            new_session.service_ticket = st
            new_session.session_id = session_id
            controller.request.session_options[:id] = session_id

            if new_session.save
              # Set the rack session record variable so the service doesn't create a duplicate session and instead updates
              # the data attribute appropriately.
              obj_with_env = controller.respond_to?(:env) ? controller : controller.request
              obj_with_env.env['rack.session.record'] = new_session
            else
              raise CASException, "Unable to store session #{session_id} for service ticket #{st} in the database."
            end
          else
            update_all_sessions(session_id, st)
          end
        end

        def get_session_for_service_ticket(st)
          session_id = read_service_session_lookup(st)
          session = session_id ? RedisSessionStore.find_by_session_id(session_id) : nil
          [session_id, session]
        end

        def read_service_session_lookup(st)
          raise CASException, 'No service_ticket specified.' unless st
          st = st.ticket if st.kind_of? ServiceTicket
          RedisSessionStore.find_by_service_ticket(st)
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
          #we still raise the exception for API compliance
          raise CASException, 'No service_ticket specified.' unless st
        end

        def save_pgt_iou(pgt_iou, pgt)
          raise CASClient::CASException.new('Invalid pgt_iou') unless pgt_iou
          raise CASClient::CASException.new('Invalid pgt') unless pgt
          pgtiou = RedisPgtiou.create(pgt_iou: pgt_iou, pgt_id: pgt)
        end

        def retrieve_pgt(pgt_iou)
          raise CASException, 'No pgt_iou specified. Cannot retrieve the pgt.' unless pgt_iou
          pgtiou = RedisPgtiou.find_by_pgt_iou(pgt_iou)
          raise CASException, 'Invalid pgt_iou specified. Perhaps this pgt has already been retrieved?' unless pgtiou

          pgt = pgtiou.pgt_id
          pgtiou.destroy
          pgt
        end

        private
        def update_all_sessions(session_id, service_ticket)
          session = RedisSessionStore.find_by_session_id(session_id)
          session["session_id"] = session_id
          session["service_ticket"] = service_ticket
          RedisSessionStore.set_session(session_id,session)
        end
        def find_by_session_id(controller, session_id)

        end
      end

      ::ACTIVE_MODEL_REDIS_TICKET_STORE = ActiveModelRedisTicketStore

      class RedisSessionStore
        include ActiveModel
        attr_accessor :session_id, :service_ticket, :data

        class << self
          attr_accessor :client, :env
        end

        def initialize(options={})
          options.each do |key, val|
            self.instance_variable_set("@#{key}", val)
          end
          self
        end

        def [](key)
          self.instance_variable_get("@#{key}")
        end

        def []=(key, value)
          self.instance_variable_set("@#{key}", value)
        end

        def self.setup_client(config)
          @@client ||= begin
            ActionDispatch::Session::ActiveModelRedisStore.new(config ,config)
          end
        end

      #   def self.client(config)
      #     redis_url = config && config[:redis_settings] && "#{config[:redis_settings]['host']}:#{config[:redis_settings]['port']}" || 'localhost:11211'
      #     options = config[:redis_settings].clone if config.has_key?(:redis_settings)
      #     options.delete("host") if options && options.has_key?("host")
      #     options.delete("port") if options && options.has_key?("port")
      #     @@options = options || {}
      #     @@redis ||= Redis.new(redis_url, @@options)
      # end

        def self.find_by_session_id(session_id)
          session_id = "#{namespaced_key(session_id)}"
          session = @@client.get_session(@env, session_id)[1]

          # Unlike Memcached, Redis .get returns a serialized hash...
          # Alternately, data could be saved as redis native hash data using redis.hmset and retrieved with .hgetall
          # However, some values may themselves be hashes which would then be stringified.
          session = JSON.parse(session) if session.is_a? String

          # A session is generated immediately without actually logging in, the below line
          # validates that we have a service_ticket so that we can store additional information
          if session
            RedisSessionStore.new(session)
          else
            return false
          end
        end

        def self.set_session(session_id, new_session)

          session = @@client.set_session(@env, session_id,new_session, {})
        end


        def self.find_by_service_ticket(service_ticket)
          session_id = @@client.get_session(@env, "#{namespaced_key(service_ticket)}")
          session = RedisSessionStore.find_by_session_id(session_id) if session_id
          session.session_id if session
        end

        def session_data
          data = {}
          self.instance_variables.each{|key| data[key.to_s.sub(/\A@/, '')] = self[key.to_s.sub(/\A@/, '')]}
          data
        end

        def client
          self.class.client
        end

        # As Redis is a key value store we are storing the session in the form of
        # session_id => {session_data}
        #
        # We do also need to be able to retrieve the session using just the service_ticket, and as
        # this is a key value store - we need to store the service_ticket as a key - pointing to
        # the session_id which will give us the session data
        # service_ticket => session_id
        # session_id => {session_data}
        def save
          @@client.set_session(@env, namespaced_key(service_ticket), session_id, {})
          # It's easiest to convert data to json, then parse when reading above in .find_by_session_id.
          @@client.set_session(@env, namespaced_key(session_id), session_data.to_json,{})
        end

        def destroy
          @@client.destroy_session(@env, namespaced_key(service_ticket),{})
          @@client.destroy_session(@env, namespaced_key(session_id),{})
        end

        alias_method :save!, :save

        # Need to access the namespaced_key method through both class methods as
        # well as instance methods.
        # Hence having the same name methods for both class and instance.
        def self.namespaced_key(key)
          if @namespace
            "#{@namespace}:#{key}"
          else
            key.to_s
          end
        end

        def namespaced_key(key)
          self.class.namespaced_key(key)
        end
      end

      class RedisPgtiou
        include ActiveModel
        attr_accessor :pgt_iou, :pgt_id

        def initialize(options={})
          @pgt_iou = options[:pgt_iou]
          @pgt_id = options[:pgt_id]
        end

        def self.setup_client(config)
          @@client ||= begin
           ActionDispatch::Session::ActiveModelRedisStore.new(config ,config)
          end
        end

        def self.find_by_pgt_iou(pgt_iou)
          debugger
          pgtiou = @@client.get_session(RedisSessionStore.env,pgt_iou)[1]
          redispgtiou =  RedisPgtiou.new(pgtiou) if pgtiou

          return redispgtiou
        end

        def self.create(options)
          pgtiou = RedisPgtiou.new(options)
          @@client.set_session({}, pgtiou.pgt_iou, pgtiou.session_data, {})
        end

        def session_data
          {pgt_iou: self.pgt_iou, pgt_id: self.pgt_id}
        end

        def destroy
          @@client.destroy_session(RedisSessionStore.env,self.pgt_iou,{})
        end
      end
    end
  end
end
