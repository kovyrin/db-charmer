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
end unless ENV['SKIP_MT_TESTS']
