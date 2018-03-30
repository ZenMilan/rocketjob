require_relative '../../test_helper'

# Unit Test for RocketJob::Job
module Plugins
  module Job
    class ThrottleTest < Minitest::Test
      class ThrottleJob < RocketJob::Job
        # Only allow one to be processed at a time
        self.throttle_running_jobs = 1
        self.pausable              = true

        def perform
          21
        end
      end

      describe RocketJob::Plugins::Job::Throttle do
        before do
          RocketJob::Job.delete_all
        end

        describe '.throttle?' do
          it 'defines the running jobs throttle' do
            assert ThrottleJob.throttle?(:throttle_running_jobs_exceeded?), ThrottleJob.rocket_job_throttles
            refute ThrottleJob.throttle?(:blah?), ThrottleJob.rocket_job_throttles
          end
        end

        describe '.undefine_throttle' do
          it 'undefines the running jobs throttle' do
            assert ThrottleJob.throttle?(:throttle_running_jobs_exceeded?), ThrottleJob.rocket_job_throttles
            ThrottleJob.undefine_throttle(:throttle_running_jobs_exceeded?)
            refute ThrottleJob.throttle?(:throttle_running_jobs_exceeded?), ThrottleJob.rocket_job_throttles
            ThrottleJob.define_throttle(:throttle_running_jobs_exceeded?)
            assert ThrottleJob.throttle?(:throttle_running_jobs_exceeded?), ThrottleJob.rocket_job_throttles
          end
        end

        describe '#throttle_running_jobs_exceeded??' do
          it 'does not exceed throttle when no other jobs are running' do
            ThrottleJob.create!
            job = ThrottleJob.new
            refute job.send(:throttle_running_jobs_exceeded?)
          end

          it 'exceeds throttle when other jobs are running' do
            job1 = ThrottleJob.new
            job1.start!
            job2 = ThrottleJob.new
            assert job2.send(:throttle_running_jobs_exceeded?)
          end

          it 'excludes paused jobs' do
            job1 = ThrottleJob.new
            job1.start
            job1.pause!
            job2 = ThrottleJob.new
            refute job2.send(:throttle_running_jobs_exceeded?)
          end

          it 'excludes failed jobs' do
            job1 = ThrottleJob.new
            job1.start
            job1.fail!
            job2 = ThrottleJob.new
            refute job2.send(:throttle_running_jobs_exceeded?)
          end
        end

        describe '.rocket_job_next_job' do
          before do
            @worker_name = 'worker:123'
          end

          after do
            @job.destroy if @job && !@job.new_record?
          end

          it 'return nil when no jobs available' do
            assert_nil RocketJob::Job.rocket_job_next_job(@worker_name)
          end

          it 'return the job when others are queued, paused, failed, or complete' do
            @job = ThrottleJob.create!
            ThrottleJob.create!(state: :failed)
            ThrottleJob.create!(state: :complete)
            ThrottleJob.create!(state: :paused)
            assert job = RocketJob::Job.rocket_job_next_job(@worker_name), -> { ThrottleJob.all.to_a.ai }
            assert_equal @job.id, job.id, -> { ThrottleJob.all.to_a.ai }
          end

          it 'return nil when other jobs are running' do
            ThrottleJob.create!
            @job = ThrottleJob.new
            @job.start!
            assert_nil RocketJob::Job.rocket_job_next_job(@worker_name), -> { ThrottleJob.all.to_a.ai }
          end

          it 'add job to filter when other jobs are running' do
            ThrottleJob.create!
            @job = ThrottleJob.new
            @job.start!
            filter = {}
            assert_nil RocketJob::Job.rocket_job_next_job(@worker_name, filter), -> { ThrottleJob.all.to_a.ai }
            assert_equal 1, filter.size
          end
        end
      end
    end
  end
end
