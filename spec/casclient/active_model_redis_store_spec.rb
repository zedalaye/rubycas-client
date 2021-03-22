require 'spec_helper'
require 'active_model_redis_store'
require 'redis'
require 'redis-store'

describe ActionDispatch::Session::ActiveModelRedisStore do

  describe 'session_destroy' do

    pool = ActionDispatch::Session::ActiveModelRedisStore.new nil, {
        :namespace => nil,
        :compress => true,
        :compress_threshold => 1.kilobyte,
        :expires_in => nil,
        :race_condition_ttl => nil,
        :error_handler => "DEFAULT_ERROR_HANDLER"


        }
        :cache => ActiveSupport::Cache::RedisStore.new("localhost:70"),
        :key => "_session_id",
        :secret => "SESSION_SECRET_KEY",
        :session_id => '12345',
        :raise_errors => true,
        :secure => false }

    subject { pool }

    it 'logs warning if pool dosnt contain session' do
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:exist?).and_return(true)
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      expect(logger).to receive(:warn).with("Session::ActiveModelRedisStore#destroy_session: the retrieved pool session for session_id 12345 is nil")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs error if session is in pool yet cannot be retrieved' do
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:exist?).and_return(true, false)
      expect(logger).to receive(:warn).with("Session::ActiveModelMemcacheStore#destroy_session: [SESSION 12345] Service ticket key present, @pool.exist?: false")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'deletes the session if it exists' do
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs Redis error if exception is raised' do
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      allow_any_instance_of(ActiveSupport::Cache::RedisCacheStore).to receive(:delete).and_raise( Redis::RedisError)
      expect { subject.destroy_session '','12345', {} }.to raise_error("Dalli::DalliError")
    end
  end
end
