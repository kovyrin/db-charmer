class Object
  unless defined?(try)
    def try(method, *options, &block)
      send(method, *options, &block)
    end
  end
end

class NilClass
  def try(method, *options, &block)
    nil
  end
end
