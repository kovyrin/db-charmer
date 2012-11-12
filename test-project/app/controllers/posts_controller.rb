class PostsController < ApplicationController
  force_slave_reads :only => [ :index, :show, :new ], :except => :new

  # We'll use this to make sure count query would be sent to a proper server
  before_filter do
    Post.count
  end

  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
  end

  def create
    post = Post.create!(params[:post])
    redirect_to(post_url(post))
  end

  def destroy
    Post.delete(params[:id])
    redirect_to(:action => :index)
  end
end
