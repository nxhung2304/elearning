class UserEntity < BaseEntity
  expose :name, documentation: { type: "String" }
  expose :email, documentation: { type: "String" }
  expose :status do |base, _options|
    base.status
  end
end
