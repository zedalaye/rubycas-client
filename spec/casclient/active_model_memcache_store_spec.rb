require 'spec_helper'
require 'active_model_memcache_store'
require 'dalli'

describe ActionDispatch::Session::ActiveModelMemcacheStore do

  describe 'session_destroy' do
    before do
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:exist?).and_return(true)
    end

    pool = ActionDispatch::Session::ActiveModelMemcacheStore.new nil, {
        :cache => ActiveSupport::Cache::DalliStore.new("localhost:70"),
        :key => "_session_id",
        :secret => "SESSION_SECRET_KEY",
        :session_id => '12345',
        :secure => false }

    subject { pool }

    it 'does not error out if session does not exist' do
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      expect(logger).to receive(:warn).with("Session::ActiveModelMemcacheStore#destroy_session: session is null: 12345")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end
  end
end
