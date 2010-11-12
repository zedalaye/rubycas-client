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

      def read_service_session_lookup(st)
        CasSession.find_by_service_ticket(st).session_id
      end

      def delete_service_session_lookup(st)
        CasSession.find_by_service_ticket(st.ticket).destroy
      end
    end
  end
end
