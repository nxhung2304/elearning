# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user && user.status_active?

    if user.admin?
      can :manage, :all
    elsif user.teacher?
      can :read, :all
      cannot :read, Course
      can :manage, Course, teacher_id: user.id
      can :update, Profile, user_id: user.id
    elsif user.student?
      can :read, User, id: user.id, discarded_at: nil
      can :update, Profile, user_id: user.id
      # TODO: change to enrollment course
      can :read, Course, status: :published
    end

    can :read, :dashboard
  end
end
