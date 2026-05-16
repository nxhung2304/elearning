puts "Creating user..."
user = User.find_or_initialize_by(email: "user@gmail.com") do |u|
  u.name = "User"
  u.password = "password"
  u.password_confirmation = "password"
  u.save!

  puts "User created: #{user.email}"
end
