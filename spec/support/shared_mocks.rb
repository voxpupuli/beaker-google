# frozen_string_literal: true

require 'securerandom'

# Add mutex_m requirement for Ruby 3.4.0 compatibility
begin
  require 'mutex_m'
rescue LoadError
  # mutex_m is not available on all Ruby versions
end

# Mock external classes that we don't want to test
class MockNetwork
  def initialize
    @name = 'test-network'
    @self_link = 'https://www.googleapis.com/compute/v1/projects/test-project/global/networks/test-network'
  end

  attr_reader :name, :self_link
end

class MockSubnetwork
  def initialize
    @name = 'test-subnetwork'
    @self_link = 'https://www.googleapis.com/compute/v1/projects/test-project/regions/us-central1/subnetworks/test-subnetwork'
  end

  attr_reader :name, :self_link
end

class MockMachineType
  def initialize
    @name = 'n1-standard-1'
    @memory_mb = 3840
    @guest_cpus = 1
  end

  attr_reader :name, :memory_mb, :guest_cpus
end

class MockImage
  def initialize
    @name = 'test-image'
    @self_link = 'https://www.googleapis.com/compute/v1/projects/test-project/global/images/test-image'
    @disk_size_gb = 20
  end

  attr_reader :name, :self_link, :disk_size_gb
end

class MockInstance
  def initialize
    @name = 'test-instance'
    @status = 'RUNNING'
    @tags = MockTags.new
    @metadata = MockMetadata.new
    @fingerprint = 'test-fingerprint'
  end

  attr_reader :name, :status, :tags, :metadata, :fingerprint
end

class MockTags
  def initialize
    @items = []
    @fingerprint = 'test-fingerprint'
  end

  attr_reader :items, :fingerprint
end

class MockMetadata
  def initialize
    @items = []
    @fingerprint = 'test-fingerprint'
  end

  attr_accessor :items
  attr_reader :fingerprint
end

class MockOperation
  def initialize
    @name = 'test-operation'
    @status = 'RUNNING'
  end

  attr_reader :name, :status
end
