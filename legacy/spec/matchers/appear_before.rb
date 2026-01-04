RSpec::Matchers.define :appear_before do |later_content|
  match do |earlier_content|
    page.body.index(earlier_content) < page.body.index(later_content)
  end
  failure_message do |earlier_content|
    "expected \"#{earlier_content}\" to appear before \"#{later_content}\""
  end
  failure_message_when_negated do |earlier_content|
    "expected \"#{earlier_content}\" to not appear before \"#{later_content}\""
  end
  description do
    "\"#{earlier_content}\" appears before \"#{later_content}\""
  end
end
