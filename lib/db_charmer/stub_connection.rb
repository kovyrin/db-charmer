module DbCharmer
  class StubConnection < ActiveRecord::ConnectionAdapters::AbstractAdapter
    def initialize; end

    def method_missing(*arg)
      raise ActiveRecord::ConnectionNotEstablished, "You have to switch connection on your model before using it"
    end
  end
end
