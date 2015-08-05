require "capybara/cucumber"
require "capybara/rspec"
require "capybara"
require 'sauce_whisk'

@browser = nil

Before do | scenario |
  Capybara.register_driver :selenium do |app|
    capabilities = {
      :version => ENV['version'],
      :browserName => ENV['browserName'],
      :platform => ENV['platform'],
      :name => "#{scenario.feature.name} - #{scenario.name}"
    }

    url = "http://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:80/wd/hub".strip
    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote, :url => url,
                                   :desired_capabilities => capabilities)
  end
  Capybara.default_wait_time = 10
  Capybara.current_driver = :selenium


  RSpec.configure do |config|
    config.include Capybara::DSL
    config.include Capybara::RSpecMatchers
  end
end

# "after all"
After do | scenario |
  sessionid = Capybara.current_session.driver.browser.session_id
  jobname = "#{scenario.feature.name} - #{scenario.name}"

  # Output sessionId and jobname to std out for Sauce OnDemand Plugin to display embeded results
  puts "SauceOnDemandSessionID=#{sessionid} job-name=#{jobname}"

  Capybara.current_session.driver.browser.close

  if scenario.passed?
    SauceWhisk::Jobs.pass_job sessionid
  else
    SauceWhisk::Jobs.fail_job sessionid
  end
end
