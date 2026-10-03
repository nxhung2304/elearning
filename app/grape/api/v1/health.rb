# frozen_string_literal: true

module API
  module V1
    class Health < Grape::API
      resource :health do
        desc "Health check"

        get do
          { status: "ok" }
        end
      end
    end
  end
end
