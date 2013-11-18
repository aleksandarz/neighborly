class Projects::BackersController < ApplicationController
  inherit_resources
  actions :show, :new, :update_info, :review, :create, :credits_checkout
  skip_before_filter :force_http, only: [:create, :update_info]
  skip_before_filter :verify_authenticity_token, only: [:moip]
  has_scope :available_to_count, type: :boolean
  has_scope :with_state
  has_scope :page, default: 1
  load_and_authorize_resource except: [:index]
  belongs_to :project, finder: :find_by_permalink!

  def index
    @project = parent
    if request.xhr? && params[:page] && params[:page].to_i > 1
      render collection
    end
  end

  def update_info
    resource.update_attributes(params[:backer])
    resource.update_user_billing_info
    render json: {message: 'updated'}
  end

  def show; end

  def new
    unless parent.online?
      flash[:failure] = t('controllers.projects.backers.new.cannot_back')
      return redirect_to :root
    end

    @create_url = ::Configuration[:secure_review_host] ?
      project_backers_url(@project, {host: ::Configuration[:secure_review_host], protocol: 'https'}) :
      project_backers_path(@project)

    @title = t('projects.backers.new.title', name: @project.name)
    @backer = @project.backers.new(user: current_user)
    empty_reward = Reward.new(minimum_value: 0, description: t('controllers.projects.backers.new.no_reward'))
    @rewards = [empty_reward] + @project.rewards.not_soon.remaining.order(:minimum_value)

    # Select
    if params[:reward_id] && (@selected_reward = @project.rewards.not_soon.find params[:reward_id]) && !@selected_reward.sold_out?
      @backer.reward = @selected_reward
      @backer.value = "%0.0f" % @selected_reward.minimum_value
    end
  end

  def create
    @backer.user = current_user
    @backer.reward_id = nil if params[:backer][:reward_id].to_i == 0
    create! do |success,failure|
      failure.html do
        flash[:failure] = t('controllers.projects.backers.create.error')
        return redirect_to new_project_backer_path(@project)
      end
      success.html do
        flash.delete(:notice)
        session[:thank_you_backer_id] = @backer.id
        return render :create
      end
    end
    @thank_you_id = @project.id
  end

  def credits_checkout
    if current_user.credits < @backer.value
      flash[:failure] = t('controllers.projects.backers.credits_checkout.no_credits')
      return redirect_to new_project_backer_path(@backer.project)
    end

    unless @backer.confirmed?
      @backer.update_attributes({ payment_method: 'Credits' })
      @backer.confirm!
    end
    flash[:success] = t('controllers.projects.backers.credits_checkout.success')
    redirect_to project_backer_path(parent, resource)
  end

  protected
  def collection
    @backers ||= apply_scopes(end_of_association_chain).available_to_display.order("confirmed_at DESC").per(10)
  end
end
