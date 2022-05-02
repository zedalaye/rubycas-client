require 'spec_helper'
require 'active_model_redis_store'
require 'redis'
require 'redis-store'
require 'redis-activesupport'
require 'redis-actionpack'

describe ActionDispatch::Session::ActiveModelRedisStore do

  describe 'session_destroy' do

    pool = ActionDispatch::Session::ActiveModelRedisStore.new nil, {
       :cache => ActiveSupport::Cache::RedisStore.new,
       :redis_server => { host: '127.0.0.1', port: 6379 , db: 0 },
       :key => "_session_id",
       :raise_errors => true,
       :secure => false
    }

    subject { pool }

    it 'logs warning if pool dosnt contain session' do
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true)
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:find_session).and_return( [{"id" => "abcd"},{ "session" => "12345"}] )
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:delete_session).and_return(true)
      allow_any_instance_of(Rack::Session::Redis).to receive(:delete_session).and_return(true)
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      expect(logger).to receive(:warn).with("Session::ActiveModelRedisStore#delete_session: the retrieved session for session_id 12345 is nil")
      expect { subject.delete_session '','12345', {} }.not_to raise_error
    end

    it 'deletes the session if it exists' do
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:exist?).and_return(true, true)
      allow_any_instance_of(ActionDispatch::Session::RedisStore).to receive(:exist?).and_return(true)
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:find_session).and_return( [{"id" => "abcd"},{ "session" => "12345"}] )
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      expect { subject.delete_session '','12345', {} }.not_to raise_error
    end

    it 'logs Redis error if exception is raised' do
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:find_session).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get_session).and_return({ service_ticket: '12345' })
      allow_any_instance_of(ActionDispatch::Session::ActiveModelRedisStore).to receive(:delete_session).and_raise( Errno::ECONNREFUSED)
      expect { subject.delete_session '','12345', {} }.to raise_error(Errno::ECONNREFUSED)
    end
  end
end
