class AuthEntity < BaseEntity
  expose :access_token, documentation: { type: "String" }
  expose :refresh_token, documentation: { type: "String" }
  expose :expires_in, documentation: { type: "Integer" }
  expose :user, using: UserEntity, documentation: { type: "UserEntity" }

  unexpose :id
  unexpose :updated_at
  unexpose :created_at
end
