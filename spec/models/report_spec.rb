require 'rails_helper'

RSpec.describe Report, type: :model do
  subject { build(:report) }

  describe "associations" do
    it { is_expected.to belong_to(:reporter).class_name("User") }
    it { is_expected.to belong_to(:resolved_by).class_name("User").optional }
    it { is_expected.to belong_to(:reportable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:reason) }
    # reporter and reportable are validated by belongs_to by default in Rails 5+ unless optional: true

    context "when reason is other" do
      before { subject.reason = :other }
      it { is_expected.to validate_presence_of(:description) }
    end

    context "when reason is spam" do
      before { subject.reason = :spam }
      it { is_expected.not_to validate_presence_of(:description) }
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:reason).with_values(spam: 0, inappropriate: 1, harassment: 2, other: 3) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, resolved: 1, dismissed: 2) }
  end
end
