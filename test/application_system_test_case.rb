require "test_helper"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if Gem.win_platform?
    Capybara.register_driver :headless_edge do |app|
      options = Selenium::WebDriver::Edge::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1440,1000")
      Capybara::Selenium::Driver.new(app, browser: :edge, options: options)
    end
    driven_by :headless_edge
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1440, 1000 ]
  end

  def login
    visit new_user_session_path
    fill_in "E-mail", with: users(:admin).email
    fill_in "Senha", with: "SenhaDeTeste123!"
    click_button "ENTRAR"
    assert_selector "h1", text: "Dashboard"
  end

  def resize_viewport(width, height)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: height, deviceScaleFactor: 1, mobile: false)
  end

  def assert_no_horizontal_overflow
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "A página possui rolagem horizontal."
  end
end
