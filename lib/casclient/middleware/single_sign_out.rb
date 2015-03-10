require 'nokogiri'

module CASClient
  module Rack
    class SingleSignOut

      def initialize(app)
        @app = app
      end

      def call(env)
        if env['REQUEST_METHOD'] == 'POST' && env['rack.request.form_hash'] && request = env['rack.request.form_hash']['logoutRequest']
          session_index = Nokogiri.HTML(request).at('sessionindex').text rescue nil

          @status, @headers, @response = if session_index.present?
             CASClient::Frameworks::Rails::Filter.client.ticket_store.process_single_sign_out(session_index)
             [200, {'Content-Type' => 'text/plain'}, ['Single sign out successful.']]
           else
             [400, {'Content-Type' => 'text/plain'}, ['Could not obtain session from request.']]
           end
        else
          @status, @headers, @response = @app.call(env)
        end
      end
    end
  end
end
