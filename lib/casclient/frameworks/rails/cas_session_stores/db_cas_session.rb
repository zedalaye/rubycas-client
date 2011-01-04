module CasSessionStore
  module DbCasSession
    def self.included(base)
      Object.const_set(:CasSession, Class.new(ActiveRecord::Base)) unless Object.const_defined?(:CasSession)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def store_service_session_lookup(st, sid)
        CasSession.create(:service_ticket => st.ticket, :session_id => sid)
      end

      # find CAS-ticket
      def read_service_session_lookup(st)
        CasSession.where(:service_ticket => st).first.try(:session_id)
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
