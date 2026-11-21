# Minimal purpose-built job (not tied to checkout/auth) whose only role is to
# give Solid Queue a real argument to serialize: Product is passed by
# reference, so ActiveJob stores it as a GlobalID in solid_queue_jobs.arguments
# and resolves it back via Product.find on perform. See
# test/security/job_arguments_fuzz_test.rb for how that resolution step is
# fuzzed (threat model KF-2: ActiveJob/GlobalID dispatch to an attacker-named
# constant).
class ReindexProductJob < ApplicationJob
  queue_as :default

  def perform(product)
    Rails.logger.info("[ReindexProductJob] reindexed product=#{product.id}")
  end
end
