# frozen_string_literal: true

module API
  module V1
    class Base < API::Base
      version "v1", using: :path

      mount API::V1::Health
      mount API::V1::Auth
    end
  end
end
