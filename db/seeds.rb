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

create_roles
create_users if Rails.env.development? || Rails.env.test?

puts "\n== Seed completed successfully =="
