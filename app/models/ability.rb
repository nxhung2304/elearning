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
      can :manage, Section, course: { teacher_id: user.id }, discarded_at: nil
    elsif user.student?
      can :read, User, id: user.id, discarded_at: nil
      can :update, Profile, user_id: user.id
      # TODO: change to enrollment course
      can :read, Course, status: :published
      can :read, Section, discarded_at: nil
    end

    can :read, :dashboard
  end
end
