require 'spec_helper'
require 'casclient/tickets/storage/active_record_ticket_store'

describe CASClient::Tickets::Storage::ActiveRecordTicketStore do
  it_should_behave_like "a ticket store"

  describe 'store_service_session_lookup' do
    it 'creates a session if none are found with the specified service' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return("nonexistant_session")
      controller.stub_chain(:env, :[]=)
      subject.store_service_session_lookup("service_ticket", controller)
      new_session = ActiveRecord::SessionStore::Session.find_by_session_id("nonexistant_session")
      new_session.service_ticket.should eql("service_ticket")
    end
  end
end
