shared_examples "a ticket store interacting with sessions" do

  before do
    stub_const("Rails::VERSION::MAJOR", 3)
  end

  describe "#store_service_session_lookup" do
    it "should raise CASException if the Service Ticket is nil" do
      expect { subject.store_service_session_lookup(nil, "controller") }.to raise_exception(CASClient::CASException, /No service_ticket specified/)
    end
    it "should raise CASException if the controller is nil" do
      expect { subject.store_service_session_lookup("service_ticket", nil) }.to raise_exception(CASClient::CASException, /No controller specified/)
    end
    it "should store the ticket without any errors" do
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], ["nonexistant_session", {"session_id" => "ST-id"}])
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["nonexistant_session", {"session_id" => "ST-id"}])
      expect { subject.store_service_session_lookup(service_ticket, mock_controller_with_session(nil, session)) }.to_not raise_exception
    end
  end

  describe "#get_session_for_service_ticket" do
    context "the service ticket is nil" do
      it "should raise CASException" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], ["nonexistant_session", {:session_id => service_ticket}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["nonexistant_session", {:session_id => service_ticket}])

        expect { subject.get_session_for_service_ticket(nil) }.to raise_exception(CASClient::CASException, /No service_ticket specified/)
      end
    end
    context "the service ticket is associated with a session" do
      before do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([],[])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return([])
        subject.store_service_session_lookup(service_ticket, mock_controller_with_session(nil, session))
        session.save!
      end
      it "should return the session_id and session for the given service ticket" do
        allow_any_instance_of(CASClient::Tickets::Storage::ActiveModelRedisTicketStore).to receive(:get_session_for_service_ticket).and_return([session.session_id,session])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(true)
        result_session_id, result_session = subject.get_session_for_service_ticket(service_ticket)
        result_session_id.should == session.session_id
        result_session.session_id.should == session.session_id
        result_session.data.should == session.data
      end
    end
    context "the service ticket is not associated with a session" do
      it "should return nils if there is no session for the given service ticket" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], [])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return([])
        subject.get_session_for_service_ticket(service_ticket).should == [nil, nil]
      end
    end
  end

  describe "#process_single_sign_out" do
    context "the service ticket is nil" do
      it "should raise CASException" do
        expect { subject.process_single_sign_out(nil) }.to raise_exception(CASClient::CASException, /No service_ticket specified/)
      end
    end
    context "the service ticket is associated with a session" do
      before do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], ["nonexistant_session", {"session_id" => "ST-id"}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["nonexistant_session", {"session_id" => "ST-id"}])
        subject.store_service_session_lookup(service_ticket, mock_controller_with_session(nil, session))
        session.save!
        subject.process_single_sign_out(service_ticket)
      end
      context "the session" do
        it "should be destroyed" do
          if subject.instance_of?(CASClient::Tickets::Storage::ActiveModelMemcacheTicketStore)
            dc = Dalli::Client.new
            dc.get(session.session_id).should be_nil
          elsif subject.instance_of?(CASClient::Tickets::Storage::ActiveModelRedisTicketStore)
            dc = ActionDispatch::Session::ActiveModelRedisStore.new nil, {
                :cache => ActiveSupport::Cache::RedisStore.new,
                :redis_server => { host: '127.0.0.1', port: 6379 , db: 0 } ,
                :key => "_session_id",
                :raise_errors => true,
                :secure => false
            }
            allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return(nil)
            dc.get_session({}, session.session_id).should nil
          else
            ActiveRecord::SessionStore::Session.find_by_session_id(session.session_id).should be_nil
          end
        end
      end
      it "should destroy session for the given service ticket" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], ["nonexistant_session", {"session_id" => "ST-id"}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["nonexistant_session", {"session_id" => "ST-id"}])
        subject.process_single_sign_out(service_ticket)
      end
    end
    context "the service ticket is not associated with a session" do
      it "should run without error if there is no session for the given service ticket" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], ["nonexistant_session", {"session_id" => "ST-id"}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["nonexistant_session", {"session_id" => "ST-id"}])
        expect { subject.process_single_sign_out(service_ticket) }.to_not raise_error
      end
    end
  end

  describe "#cleanup_service_session_lookup" do
    context "the service ticket is nil" do
      it "should raise CASException" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], [])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return([])
        expect { subject.cleanup_service_session_lookup(nil) }.to raise_exception(CASClient::CASException, /No service_ticket specified/)
      end
    end
    it "should run without error" do
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([], [])
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return([])
      expect { subject.cleanup_service_session_lookup(service_ticket) }.to_not raise_exception
    end
  end
end

shared_examples "a ticket store" do
  let(:ticket_store) { described_class.new }
  let(:service_url) { "https://www.example.com/cas" }
  let(:global_session_id) {rand(1000)}
  let(:session) do
    if ticket_store.is_a?(CASClient::Tickets::Storage::ActiveModelMemcacheTicketStore)
      dc = Dalli::Client.new
      session_id = global_session_id
      memcache_data = CASClient::Tickets::Storage::MemcacheSessionStore.new("session_id" => "#{session_id}", "data" => {})
      dc.set("session#{session_id}", memcache_data)
      memcache_data
    elsif ticket_store.is_a?(CASClient::Tickets::Storage::ActiveModelRedisTicketStore)
      dc = ActionDispatch::Session::ActiveModelRedisStore.new nil, {
          :cache => ActiveSupport::Cache::RedisStore.new,
          :redis_server => { host: '127.0.0.1', port: 6379 , db: 0 } ,
          :key => "_session_id",
          :raise_errors => true,
          :secure => false
      }
      session_id = global_session_id
      cache_data = CASClient::Tickets::Storage::RedisSessionStore.new("session_id" => "#{session_id}", "data" => {})
      dc.set_session({}, session_id, cache_data, {})
      cache_data
    else
      ActiveRecord::SessionStore::Session.create!(:session_id => "session#{rand(1000)}", :data => {})
    end
  end
  subject { ticket_store }

  context "when dealing with sessions, Service Tickets, and Single Sign Out" do
    context "and the service ticket is a String" do
      it_behaves_like "a ticket store interacting with sessions" do
        let(:service_ticket) { "ST-ABC#{rand(1000)}" }
      end
    end
    context "and the service ticket is a ServiceTicket" do
      it_behaves_like "a ticket store interacting with sessions" do
        let(:service_ticket) { CASClient::ServiceTicket.new("ST-ABC#{rand(1000)}", service_url) }
      end
    end
    context "and the service ticket is a ProxyTicket" do
      it_behaves_like "a ticket store interacting with sessions" do
        let(:service_ticket) { CASClient::ProxyTicket.new("ST-ABC#{rand(1000)}", service_url) }
      end
    end
  end

  context "when dealing with Proxy Granting Tickets and their IOUs" do
    let(:pgt) { "my_pgt_#{rand(1000)}" }
    let(:pgt_iou) { "my_pgt_iou_#{rand(1000)}" }

    describe "#save_pgt_iou" do
      it "should raise CASClient::CASException if the pgt_iou is nil" do
        expect { subject.save_pgt_iou(nil, pgt) }.to raise_exception(CASClient::CASException, /Invalid pgt_iou/)
      end
      it "should raise CASClient::CASException if the pgt is nil" do
        expect { subject.save_pgt_iou(pgt_iou, nil) }.to raise_exception(CASClient::CASException, /Invalid pgt/)
      end
    end

    describe "#retrieve_pgt" do
      before do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}])
        subject.save_pgt_iou(pgt_iou, pgt)
      end
      it "should return the stored pgt" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}])
        subject.retrieve_pgt(pgt_iou).should == pgt
      end

      it "should raise CASClient::CASException if the pgt_iou isn't in the store" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return([],[])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return([],[])
        expect { subject.retrieve_pgt("not_my"+pgt_iou) }.to raise_exception(CASClient::CASException, /Invalid pgt_iou/)
      end

      it "should not return the stored pgt a second time" do
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],[])
        allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:set_session).and_return(["session_id_1",{:pgt_iou => pgt_iou, :pgt_id=> pgt}],[])
        subject.retrieve_pgt(pgt_iou).should == pgt
        expect { subject.retrieve_pgt(pgt_iou) }.to raise_exception(CASClient::CASException, /Invalid pgt_iou/)
      end
    end
  end
end
