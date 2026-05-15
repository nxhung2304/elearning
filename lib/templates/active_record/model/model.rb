<% module_namespacing do -%>
class <%= class_name %> < ApplicationRecord
<% attributes.select(&:reference?).each do |attr| -%>
  belongs_to :<%= attr.name %><%= ", polymorphic: true" if attr.polymorphic? %>
<% end -%>
<% attributes.reject(&:reference?).select { |a| %w[string text].include?(a.type.to_s) }.each do |attr| -%>
  validates :<%= attr.name %>, presence: true
<% end -%>
<% attributes.select(&:token?).each do |attr| -%>
  has_secure_token<% if attr.name != "token" %> :<%= attr.name %><% end %>
<% end -%>
<% if attributes.any?(&:password_digest?) -%>
  has_secure_password
<% end -%>

  def self.ransackable_attributes(auth_object = nil)
    attribute_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
<% end -%>
