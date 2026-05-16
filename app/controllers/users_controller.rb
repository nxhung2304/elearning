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
      redirect_to @user
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    account_params = update_params

    if @user.update(account_params)
      flash[:success] = t("controller.updated", text: email_user_message)
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: t("users.destroy.cannot_delete_self") and return
    end

    @user.status_deleted!
    redirect_to users_path, notice: t("controller.destroyed", text: email_user_message)
  end

  def me
    redirect_to user_path(current_user)
  end

  private

    def email_user_message
      User.model_name.human + " " + @user.email
    end

    def set_user
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to users_path, alert: t("errors.not_found")
    end

    def update_params
      user_params.reject { |k, v| /password/.match?(k) && v.blank? }
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :status)
    end
end
