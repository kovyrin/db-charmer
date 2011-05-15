module DbCharmer
  @@current_controller = nil
  mattr_accessor :current_controller

  def self.force_slave_reads?
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
end
