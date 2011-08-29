task :default => "jekyll:server"

namespace :jekyll do

  desc 'Delete generated _site files'
  task :clean do
    system "rm -fR _site"
  end
  
  desc 'Run the jekyll dev server'
  task :server => :clean do
    system "jekyll --server --auto"
  end
end

