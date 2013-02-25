module DbCharmer
  def self.with_remapped_databases(mappings, &proc)
    old_mappings = ::ActiveRecord::Base.db_charmer_database_remappings
    begin
      ::ActiveRecord::Base.db_charmer_database_remappings = mappings
      if mappings[:master] || mappings['master']
        with_all_hijacked(&proc)
      else
        proc.call
      end
    ensure
      ::ActiveRecord::Base.db_charmer_database_remappings = old_mappings
    end
  end

  def self.hijack_new_classes?
    !! Thread.current[:db_charmer_hijack_new_classes]
  end

private

  def self.with_all_hijacked
    old_hijack_new_classes = Thread.current[:db_charmer_hijack_new_classes]
    begin
      Thread.current[:db_charmer_hijack_new_classes] = true
      subclasses_method = DbCharmer.rails3? ? :descendants : :subclasses
      ::ActiveRecord::Base.send(subclasses_method).each do |subclass|
        subclass.hijack_connection!
      end
      yield
    ensure
      Thread.current[:db_charmer_hijack_new_classes] = old_hijack_new_classes
    end
  end
end

#---------------------------------------------------------------------------------------------------
# Hijack connection on all new AR classes when we're in a block with main AR connection remapped
class ActiveRecord::Base
  class << self
    def inherited_with_hijacking(subclass)
      out = inherited_without_hijacking(subclass)
      hijack_connection! if DbCharmer.hijack_new_classes?
      out
    end

    alias_method_chain :inherited, :hijacking
  end
end
