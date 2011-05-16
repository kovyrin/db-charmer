module DbCharmer
  @@current_controller = nil
  mattr_accessor :current_controller

  @@forced_slave_reads = false

  def self.force_slave_reads?
    # If global force slave reads is requested, do it
    return @@forced_slave_reads if @@forced_slave_reads

    # If not, try to use current controller to decide on this
    return false unless current_controller.respond_to?(:force_slave_reads?)

    slave_reads = current_controller.force_slave_reads?
    logger.debug("Using controller to figure out if slave reads should be forced: #{slave_reads}")
    return slave_reads
  end

  def self.with_controller(controller)
    raise ArgumentError, "No block given" unless block_given?
    logger.debug("Setting current controller for db_charmer: #{controller.class.name}")
    self.current_controller = controller
    yield
  ensure
    logger.debug('Clearing current controller for db_charmer')
    self.current_controller = nil
  end

  def self.force_slave_reads
    raise ArgumentError, "No block given" unless block_given?
    @@forced_slave_reads = true
    yield
  ensure
    @@forced_slave_reads = false
  end
end
