# Since Ruby community could not decide on the name of an empty object classes for many years now,
# let's just try to guess what name should we use or just bail out if we could not.
#
module DbCharmer
  if defined?(ActiveSupport::ProxyObject)
    EMPTY_BASE_CLASS = ActiveSupport::ProxyObject
  elsif defined?(ActiveSupport::BasicObject)
    EMPTY_BASE_CLASS = ActiveSupport::BasicObject
  elsif defined?(BlankSlate)
    EMPTY_BASE_CLASS = BlankSlate
  else
    raise NotImplementedError, "Seriously, I do not know how often could they change empty object class names?!"
  end

  class EmptyObject < EMPTY_BASE_CLASS
    # We need to do this because in Rails 2.3 BasicObject does not remove object_id method, which is stupid
    undef_method(:object_id) if instance_methods.member?('object_id')
  end
end
