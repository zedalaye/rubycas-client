require 'spec_helper'
require 'casclient/middleware/single_sign_out'
require 'casclient/frameworks/rails/filter'

describe CASClient::Rack::SingleSignOut do
  before do
    @app = double
    @ticket_store = double
    @middleware = CASClient::Rack::SingleSignOut.new(@app)
    CASClient::Frameworks::Rails::Filter.stub_chain(:client, :ticket_store).and_return(@ticket_store)
  end

  it 'processes a valid single sign out request' do
    env = { 'REQUEST_METHOD' => 'POST', 'rack.request.form_hash' => {'logoutRequest' => %{
        <samlp:LogoutRequest ID="12345" Version="2.0" IssueInstant="Tue, 10 Mar 2015 12:48:23 -0400">
        <saml:NameID></saml:NameID>
        <samlp:SessionIndex>ST-12345678910</samlp:SessionIndex>
        </samlp:LogoutRequest> } }
    }
    @ticket_store.should_receive(:process_single_sign_out)
    @middleware.call(env).first.should eq(200)
  end


  it 'retrieves the session index from the logut request xml' do
    env = { 'REQUEST_METHOD' => 'POST', 'rack.request.form_hash' => {'logoutRequest' => %{
        <samlp:LogoutRequest ID="12345" Version="2.0" IssueInstant="Tue, 10 Mar 2015 12:48:23 -0400">
        <saml:NameID></saml:NameID>
        <samlp:SessionIndex>ST-12345678910</samlp:SessionIndex>
        </samlp:LogoutRequest> } }
    }
    @ticket_store.should_receive(:process_single_sign_out).with('ST-12345678910')
    @middleware.call(env).first.should eq(200)
  end

  it 'reports a bad request if service ticket could not be retrieved' do
    env = { 'REQUEST_METHOD' => 'POST', 'rack.request.form_hash' => {'logoutRequest' => %{
        <samlp:LogoutRequest ID="12345" Version="2.0" IssueInstant="Tue, 10 Mar 2015 12:48:23 -0400">
        <saml:NameID></saml:NameID>
        <samlp:SessionIndex></samlp:SessionIndex>
        </samlp:LogoutRequest> } }
    }
    @middleware.call(env).first.should eq(400)
  end

  ['GET', 'PUT', 'DELETE'].each do |method|
    it "continues down the middleware stack when the request method is #{method}" do
      env = { 'REQUEST_METHOD' => method }
      @app.should_receive(:call)
      @middleware.call(env)
    end
  end
end
