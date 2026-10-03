# frozen_string_literal: true

module Api
  module V1
    class Base < Api::Base
      version "v1", using: :path

      mount Api::V1::Health
      mount Api::V1::Auth
    end
  end
end
