module ActiveModelRedisTicketStoreHelpers
  class << self
    def setup_redis_store
      @redis_mock_store = {}
      ActionDispatch::Session::ActiveModelRedisStore.any_instance.stub(:set_session) do |key, value|
        @redis_mock_store[key] = value
      end
      ActionDispatch::Session::ActiveModelRedisStore.any_instance.stub(:get_session) do |key|
        @redis_mock_store[key]
      end
      ActionDispatch::Session::ActiveModelRedisStore.any_instance.stub(:destroy_session) do |key|
        @redis_mock_store.delete(key)
        @redis_mock_store
      end
    end

    def teardown_redis_store
      @redis_mock_store = {}
    end
  end
end
