class Object
  unless defined?(try)
    def try(method, *options, &block)
      send(method, *options, &block)
    end
  end

  # These methods are added to all objects so we could call proxy? on anything
  # and figure if an object is a proxy w/o hitting method_missing or respond_to?
  def self.proxy?
    false
  end

  def proxy?
    false
  end
end

class NilClass
  def try(method, *options, &block)
    nil
  end
end
