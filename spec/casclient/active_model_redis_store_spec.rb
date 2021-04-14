require 'spec_helper'
require 'active_model_redis_store'
require 'redis'
require 'redis-store'

describe ActionDispatch::Session::ActiveModelRedisStore do

  describe 'session_destroy' do

    redis = ActionDispatch::Session::RedisStore.new nil, {
        :redis_server => nil,
        :key => nil,
        :namespace => nil,
        :expire_after => nil,
        :secret => nil,
        :secure => nil
        }

    subject { redis }

    it 'logs warning if redis dosnt contain session' do
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true)
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      expect(logger).to receive(:warn).with("Session::ActiveModelRedisStore#destroy_session: the retrieved pool session for session_id 12345 is nil")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs error if session is in redis yet cannot be retrieved' do
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true, false)
      expect(logger).to receive(:warn).with("Session::ActiveModelMemcacheStore#destroy_session: [SESSION 12345] Service ticket key present, @pool.exist?: false")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'deletes the session if it exists' do
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs Redis error if exception is raised' do
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(AActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:delete).and_raise( Errno::ECONNREFUSED)
      expect { subject.destroy_session '','12345', {} }.to raise_error("Dalli::DalliError")
    end
  end
end
