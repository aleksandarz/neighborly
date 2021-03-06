class Users::BackersController < ApplicationController
  inherit_resources
  defaults resource_class: Backer, collection_name: 'backs', instance_name: 'back'
  belongs_to :user
  actions :index

  def request_refund
    authorize! :request_refund, resource
    if resource.value > resource.user.user_total.credits
      flash[:failure] = I18n.t('controllers.users.backers.request_refund.insufficient_credits')
    elsif can?(:request_refund, resource) && resource.can_request_refund?
      resource.request_refund!
      flash[:notice] = I18n.t('controllers.users.backers.request_refund.refunded')
    end

    redirect_to credits_user_path(parent)
  end

  protected
  def collection
    @backs = end_of_association_chain.available_to_display.order("created_at DESC, confirmed_at DESC")
    @backs = @backs.not_anonymous.with_state('confirmed') unless can? :manage, @user
    @backs = @backs.includes(:user, :reward, project: [:user, :category, :project_total])
  end
end
