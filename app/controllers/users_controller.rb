class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(@q.result(distinct: true))
  end

  def show; end

  def new
    @user = User.new
  end

  def edit; end

  def create
    @user = User.new(user_params)

    if @user.save
      flash[:success] = t("controller.created", text: email_user_message)
      redirect_to users_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    account_params = update_params

    if @user.update(account_params)
      flash[:success] = t("controller.updated", text: email_user_message)
      redirect_to users_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.status_deleted!
    redirect_to users_path, notice: t("controller.destroyed", text: email_user_message)
  end

  private

    def email_user_message
      User.model_name.human + " " + @user.email
    end

    def set_user
      @user = User.find(params[:id])
    end

    def update_params
      params = user_params
      if params[:password].blank?
        params = params.except(:password)
        params = params.except(:password_confirmation) if params[:password_confirmation].blank?
      end
      params
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :status)
    end
end
