require_relative 'test_helper'
require_relative 'jobs/test_job'

# Unit Test for RocketJob::Job
class DirmonEntryTest < Minitest::Test
  context RocketJob::DirmonEntry do
    teardown do
      @dirmon_entry.destroy if @dirmon_entry && @dirmon_entry.new_record?
    end

    context '.config' do
      should 'support multiple databases' do
        assert_equal 'test_rocketjob', RocketJob::DirmonEntry.collection.db.name
      end
    end

    context '#validate' do
      should 'existance' do
        assert entry = RocketJob::DirmonEntry.new(job_name: 'Jobs::TestJob')
        assert_equal false, entry.valid?
        assert_equal ["can't be blank"], entry.errors[:path], entry.errors.inspect
      end

      should 'job_name' do
        assert entry = RocketJob::DirmonEntry.new(path: '/abc/**')
        assert_equal false, entry.valid?
        assert_equal ["can't be blank", "job_name must be defined and must be derived from RocketJob::Job"], entry.errors[:job_name], entry.errors.inspect
      end

      should 'arguments' do
        assert entry = RocketJob::DirmonEntry.new(
            job_name: 'Jobs::TestJob',
            path:     '/abc/**'
          )
        assert_equal false, entry.valid?
        assert_equal ["There must be 1 argument(s)"], entry.errors[:arguments], entry.errors.inspect
      end

      should 'arguments with perform_method' do
        assert entry = RocketJob::DirmonEntry.new(
            job_name:       'Jobs::TestJob',
            path:           '/abc/**',
            perform_method: :sum
          )
        assert_equal false, entry.valid?
        assert_equal ["There must be 2 argument(s)"], entry.errors[:arguments], entry.errors.inspect
      end

      should 'valid' do
        assert entry = RocketJob::DirmonEntry.new(
            job_name:  'Jobs::TestJob',
            path:      '/abc/**',
            arguments: [1]
          )
        assert entry.valid?, entry.errors.inspect
      end

      should 'valid with perform_method' do
        assert entry = RocketJob::DirmonEntry.new(
            job_name:       'Jobs::TestJob',
            path:           '/abc/**',
            perform_method: :sum,
            arguments:      [1, 2]
          )
        assert entry.valid?, entry.errors.inspect
      end
    end

  end
end