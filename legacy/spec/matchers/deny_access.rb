RSpec::Matchers.define :deny_access do |expected|
  match do |actual|
    expect(actual).to redirect_to Rails.application.routes.url_helpers.root_path
  end
  failure_message do |actual|
    "expected to deny access"
  end
  failure_message_when_negated do |actual|
    "expected not to to deny access"
  end
  description do
    "redirect to root page and deny access"
  end
end
