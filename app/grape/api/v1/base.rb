# frozen_string_literal: true

module API
  module V1
    class Base < Grape::API
      version "v1", using: :path

      mount API::V1::Health
    end
  end
end
