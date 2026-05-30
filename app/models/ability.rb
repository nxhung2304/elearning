# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user && user.status_active?

    if user.admin?
      can :manage, :all
    elsif user.teacher?
      can :read, :all
      can :update, Profile, user_id: user.id
    elsif user.student?
      can :read, User, id: user.id
      can :update, Profile, user_id: user.id
    end

    can :read, :dashboard
  end
end
