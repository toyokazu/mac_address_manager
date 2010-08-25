class WorkerRecord < ActiveRecord::Base
  acts_as_versioned :max_version_limit => 30
  acts_as_paranoid
end
