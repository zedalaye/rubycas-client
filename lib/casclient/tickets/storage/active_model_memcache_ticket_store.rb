module CASClient
  module Tickets
    module Storage
      class ActiveModelMemcacheTicketStore < AbstractTicketStore
        def initialize(config={})
          config ||= {}
        end
        
        def store_service_session_lookup(st, controller)
          raise CASException, 'No service_ticket specified.' unless st
          raise CASException, 'No controller specified.' unless controller

          st = st.ticket if st.kind_of? ServiceTicket
          session_id = session_id_from_controller(controller)

          # Create a session in the DB if it hasn't already been created.
          unless MemcacheSessionStore.find_by_service_ticket(st)
            log.info("RubyCAS Client did not find #{session_id} in the Session Store. Creating it now!")
            # We need to use .save instead of .create or the service_ticket won't be stored
            new_session = MemcacheSessionStore.new
            new_session.service_ticket = st
            new_session.session_id = session_id
            new_session.data = {}
            if new_session.save
              # Set the rack session record variable so the service doesn't create a duplicate session and instead updates
              # the data attribute appropriately.
              controller.env['rack.session.record'] = new_session
            else
              raise CASException, "Unable to store session #{session_id} for service ticket #{st} in the database."
            end
          else
            update_all_sessions(session_id, st)
          end
        end

        def read_service_session_lookup(st)
          raise CASException, "No service_ticket specified." unless st
          st = st.ticket if st.kind_of? ServiceTicket
          session = MemcacheSessionStore.find_by_service_ticket(st)
          session ? session.session_id : nil
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
          #we still raise the exception for API compliance
          raise CASException, "No service_ticket specified." unless st
        end

        private
        def update_all_sessions(session_id, st)
          # to be implemented
        end

      end

      ::ACTIVE_MODEL_MEMCACHE_TICKET_STORE = ActiveModelMemcacheTicketStore

      class MemcacheSessionStore
        include ActiveModel::Model
        attr_accessor :id, :session_id, :data, :created_at, :updated_at, :service_ticket

        def self.find_by_service_ticket(service_ticket)
          st = Rails.application.config.session_options[:cache].get("service_ticket:#{service_ticket}")
          Marshal.load(st) if st
        end

        def save
          Rails.application.config.session_options[:cache].set(cache_token, Marshal.dump(self))
        end

        private
        def cache_token
          "service_ticket:#{self.service_ticket}"
        end
      end

    end
  end
end
