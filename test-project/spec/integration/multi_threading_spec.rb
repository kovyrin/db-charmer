require 'spec_helper'

describe "DbCharmer integration tests" do
  def do_test(test_seconds, thread_count)
    start_time = Time.now.to_f
    threads = Array.new

    while threads.size < thread_count
      threads <<  Thread.new do
        while Time.now.to_f - start_time < test_seconds do
          User.create!(:login => "user#{rand}", :password => rand)
          User.uncached { User.on_db(:slave01).first }
        end
      end
    end

    # Wait for threads to finish
    threads.each(&:join)
  end

  it "should work in single-threaded mode" do
    do_test(10, 1)
  end

  it "should work with 5 threads" do
    do_test(10, 5)
  end

  it "should use default connection passed in db_magic call in all threads" do
    # Define a class with db magic in it
    class TestLogRecordWithThreads < ActiveRecord::Base
      self.table_name = :log_records
      db_magic :connection => :logs
    end

    # Check conection in the same thread
    TestLogRecordWithThreads.connection.db_charmer_connection_name.should == "logs"

    # Check connection in a different thread
    Thread.new {
      TestLogRecordWithThreads.connection.db_charmer_connection_name.should == "logs"
    }.join
  end
end unless ENV['SKIP_MT_TESTS']
