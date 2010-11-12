module CasSessionStore
  module FileCasSession
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Creates a file in tmp/sessions linking a SessionTicket
      # with the local Rails session id. The file is named
      # cas_sess.<session ticket> and its text contents is the corresponding 
      # Rails session id.
      # Returns the filename of the lookup file created.
      def store_service_session_lookup(st, sid)
        st = st.ticket
        f = File.new(filename_of_service_session_lookup(st), 'w')
        f.write(sid)
        f.close
        return f.path
      end
      
      # Returns the local Rails session ID corresponding to the given
      # ServiceTicket. This is done by reading the contents of the
      # cas_sess.<session ticket> file created in a prior call to 
      # #store_service_session_lookup.
      def read_service_session_lookup(st)
        ssl_filename = filename_of_service_session_lookup(st)
        return File.exists?(ssl_filename) && IO.read(ssl_filename)
      end
      
      # Removes a stored relationship between a ServiceTicket and a local
      # Rails session id. This should be called when the session is being
      # closed.
      #
      # See #store_service_session_lookup.
      def delete_service_session_lookup(st)
        ssl_filename = filename_of_service_session_lookup(st)
        File.delete(ssl_filename) if File.exists?(ssl_filename)
      end
      
      # Returns the path and filename of the service session lookup file.
      def filename_of_service_session_lookup(st)
        return "#{RAILS_ROOT}/tmp/sessions/cas_sess.#{st}"
      end
    end
  end
end
