CI.run do
  step "Style: Ruby", "bundle exec rubocop"
  step "Security: Gems", "bundle exec bundler-audit check --update"
  step "Security: JavaScript", "bundle exec ruby bin/importmap audit"
  step "Security: Brakeman", "bundle exec brakeman --no-pager"
  step "Test database", "bundle exec rails db:prepare RAILS_ENV=test"
  step "Tests: Rails", "bundle exec rails test"
  step "Tests: Browser", "bundle exec rails test:system"
end
