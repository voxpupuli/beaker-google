# frozen_string_literal: true

SimpleCov.configure do
  add_filter 'spec/'
  add_filter 'vendor/'
  add_filter do |file|
    file.lines_of_code < 10
  end
end

SimpleCov.start if ENV['BEAKER_GOOGLE_COVERAGE']
