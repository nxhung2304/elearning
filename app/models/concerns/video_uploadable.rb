module VideoUploadable
  extend ActiveSupport::Concern

  ACCEPTED_VIDEO_TYPES = %w[video/mp4 video/webm].freeze
  MAX_VIDEO_SIZE = 100.megabytes
end
