module ActiveModelMemcacheTicketStoreHelpers
  class << self
    def setup_memcache_store
      @memcache_mock_store = {}
      Dalli::Client.any_instance.stub(:set) do |key, value|
        @memcache_mock_store[key] = value
      end
      Dalli::Client.any_instance.stub(:get) do |key|
        @memcache_mock_store[key]
      end
      Dalli::Client.any_instance.stub(:delete) do |key|
        @memcache_mock_store.delete(key)
        @memcache_mock_store
      end
    end

    def teardown_memcache_store
      @memcache_mock_store = {}
    end
  end
end