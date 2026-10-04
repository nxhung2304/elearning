class UserEntity < BaseEntity
  expose :id
  expose :name, documentation: { type: "String" }

  expose :email, documentation: { type: "String" }

  expose :status
end
