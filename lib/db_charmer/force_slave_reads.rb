module DbCharmer
  def self.current_controller
    Thread.current[:db_charmer_current_controller]
  end

  def self.current_controller=(val)
    Thread.current[:db_charmer_current_controller] = val
  end

  #-------------------------------------------------------------------------------------------------
  def self.forced_slave_reads_setting
    Thread.current[:db_charmer_forced_slave_reads]
  end

  def self.forced_slave_reads_setting=(val)
    Thread.current[:db_charmer_forced_slave_reads] = val
  end

  #-------------------------------------------------------------------------------------------------
  def self.force_slave_reads?
    # If global force slave reads is requested, do it
    return true if Thread.current[:db_charmer_forced_slave_reads]

    # If not, try to use current controller to decide on this
    return false unless current_controller.respond_to?(:force_slave_reads?)

    slave_reads = current_controller.force_slave_reads?
    logger.debug("Using controller to figure out if slave reads should be forced: #{slave_reads}")
    return slave_reads
  end

  #-------------------------------------------------------------------------------------------------
  def self.with_controller(controller)
    raise ArgumentError, "No block given" unless block_given?
    logger.debug("Setting current controller for db_charmer: #{controller.class.name}")
    self.current_controller = controller
    yield
  ensure
    logger.debug('Clearing current controller for db_charmer')
    self.current_controller = nil
  end

  #-------------------------------------------------------------------------------------------------
  # Force all reads in a block of code to go to a slave
  def self.force_slave_reads
    raise ArgumentError, "No block given" unless block_given?
    old_forced_slave_reads = self.forced_slave_reads_setting
    begin
      self.forced_slave_reads_setting = true
      yield
    ensure
      self.forced_slave_reads_setting = old_forced_slave_reads
    end
  end
end
