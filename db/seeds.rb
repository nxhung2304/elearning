def create_roles
  puts "\n== Creating roles =="

  Role::CODES.each do |code|
    role = Role.find_or_create_by!(code: code) do |r|
      r.name = code.capitalize
    end

    puts "✓ Role: #{role.code}"
  end
end

def create_users
  puts "\n== Creating users =="

  users = [
    {
      email: "admin@example.com",
      name: "Admin User",
      role: "admin"
    },
    {
      email: "teacher@example.com",
      name: "Teacher User",
      role: "teacher"
    },
    {
      email: "student@example.com",
      name: "Student User",
      role: "student"
    }
  ]

  roles_by_code = Role.all.index_by(&:code)

  users.each do |params|
    role_code = params.delete(:role)

    user = User.find_or_create_by!(email: params[:email]) do |u|
      u.name = params[:name]
      u.password = "password"
      u.password_confirmation = "password"
    end

    role = roles_by_code[role_code]

    unless user.roles.exists?(code: role_code)
      user.roles << role
      puts "✓ Assigned role '#{role_code}' to #{user.email}"
    end

    puts "✓ User: #{user.email}"
  end
end

def create_course_categories
  puts "\n== Creating course categories =="

  [
    "Programming",
    "Mobile Development",
    "Web Development"
  ].each do |name|
    category = CourseCategory.find_or_create_by!(name: name)
    puts "✓ Category: #{category.name}"
  end
end

def create_courses
  puts "\n== Creating courses =="

  teacher = User.find_by!(email: "teacher@example.com")

  courses = [
    {
      title: "Ruby on Rails for Beginners",
      description: "Learn Rails from scratch.",
      category: "Programming",
      price: 99.99,
      total_lessons: 12,
      level: :beginner,
      language: :english,
      status: :published,
      published_at: Time.current
    },
    {
      title: "Flutter Advanced",
      description: "Build production-ready Flutter apps.",
      category: "Mobile Development",
      price: 149.99,
      total_lessons: 20,
      level: :advanced,
      language: :english,
      status: :draft
    }
  ]

  categories = CourseCategory.all.index_by(&:name)

  courses.each do |params|
    category_name = params.delete(:category)

    course = Course.find_or_initialize_by(title: params[:title])

    course.assign_attributes(
      params.merge(
        category: categories[category_name],
        teacher: teacher
      )
    )

    course.save!

    puts "✓ Course: #{course.title}"
  end
end

create_roles
create_users if Rails.env.development? || Rails.env.test?
create_course_categories
create_courses

puts "\n== Seed completed successfully =="
