class PostsController < UserstampController
  def edit
    @post = Post.find(params[:id])
    render(:inline  => "<%= @post.title %>")
  end
  
  def update
    @post = Post.find(params[:id])
    @post.update_attributes(params[:post])
    render(:inline => "<%= @post.title %>")
  end

  protected
    def current_user
      Person.find(session[:person_id])
    end
    
    def set_stampers
      Person.stamper = self.current_user
    end

    def reset_stampers
      Person.reset_stamper
    end    
  #end
end