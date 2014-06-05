module CasSessionStore
  module DbCasSession
    def self.included(base)
      Object.const_set(:CasSession, Class.new(ActiveRecord::Base)) unless Object.const_defined?(:CasSession)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def store_service_session_lookup(st, sid)
        raise CASException, 'No service_ticket specified.' unless st
        raise CASException, 'No session specified.' unless sid
        # We need to use .save instead of .create or the service_ticket won't be stored
        cas = CasSession.new
        cas.service_ticket = st.ticket
        cas.session_id = sid
        raise CASException, "Unable to store session #{sid} for service ticket #{st}" unless cas.save
      end

      # find CAS-ticket
      def read_service_session_lookup(st)
        obj = CasSession.where(:service_ticket => st).first
        obj.session_id if obj
      end

      # delete CAS-ticket
      def delete_service_session_lookup(st)
        # efficient but doesn't invoke callbacks
        # CasSession.delete_all(:service_ticket => st)
        # not so efficient but does invoke callbacks
        CasSession.destroy_all(:service_ticket => st)
      end
    end
  end
end
