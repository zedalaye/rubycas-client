
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

end

shared_examples "a ticket store" do
  let(:ticket_store) { described_class.new }
  let(:service_url) { "https://www.example.com/cas" }
  let(:session) do
    if ticket_store.is_a?(CASClient::Tickets::Storage::ActiveModelMemcacheTicketStore)
      dc = Dalli::Client.new
      session_id = rand(1000)
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
      session_id = rand(1000)
      cache_data = CASClient::Tickets::Storage::RedisSessionStore.new("session_id" => "#{session_id}", "data" => {})
      dc.set_session({}, session_id, cache_data,{})
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
