require "test_helper"

class LocalizationTest < ActionView::TestCase
  test "formats currency dates and Fortaleza local time" do
    assert_equal "R$ 1.250,00", number_to_currency(BigDecimal("1250.00"))
    assert_equal "02/10/2026", I18n.l(Date.new(2026, 10, 2))
    assert_equal "America/Fortaleza", Time.zone.name
    assert_equal "01/10/2026 23:30", I18n.l(Time.utc(2026, 10, 2, 2, 30).in_time_zone)
    assert_equal "23:30", I18n.l(Time.utc(2026, 10, 2, 2, 30).in_time_zone, format: :short)
  end
end
