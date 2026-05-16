puts "Creating user..."
user = User.find_or_initialize_by(email: "user@gmail.com")
if user.new_record?
  user.assign_attributes(
    name: "User",
    password: "password",
    password_confirmation: "password"
  )
  user.save!
else
  puts "User with email #{user.email} already exists."
end
