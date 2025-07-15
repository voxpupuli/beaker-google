# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BeakerGoogle do
  describe 'VERSION' do
    it 'has a version number' do
      expect(BeakerGoogle::VERSION).not_to be_nil
    end

    it 'is a string' do
      expect(BeakerGoogle::VERSION).to be_a(String)
    end

    it 'follows semantic versioning pattern' do
      expect(BeakerGoogle::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
