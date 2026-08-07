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
      can :manage, Lesson, section: { course:  { teacher_id: user.id } }
      can :manage, LessonResource, lesson: { section: { course: { teacher_id: user.id } } }
    elsif user.student?
      can :read, User, id: user.id, discarded_at: nil
      can :update, Profile, user_id: user.id
      can :read, Course, status: :published
      can :read, Section, discarded_at: nil
      can %i[read create destroy], Enrollment, user_id: user.id

      # Preview lessons in any published course (trailer / marketing)
      can :read, Lesson, is_published: true, is_preview: true,
        section: { course: { status: :published } }

      # Published lessons in courses the student is actively enrolled in
      enrolled_course_ids = user.enrollments.active.pluck(:course_id)
      can :read, Lesson, is_published: true,
        section: { course: { id: enrolled_course_ids } }
    end

    can :read, :dashboard
  end
end
