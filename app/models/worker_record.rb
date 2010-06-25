class WorkerRecord < ActiveRecord::Base
  acts_as_versioned
  acts_as_paranoid
end
