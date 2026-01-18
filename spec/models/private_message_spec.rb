require 'rails_helper'

RSpec.describe PrivateMessage, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:sender).class_name('User').optional }
    it { is_expected.to belong_to(:receiver).class_name('User').optional }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:receiver_id) }
  end

  describe "Scopes" do
    let(:sender) { create(:user) }
    let(:receiver) { create(:user) }
    let!(:message1) { create(:private_message, sender: sender, receiver: receiver, read: false) }
    let!(:message2) { create(:private_message, sender: sender, receiver: receiver, read: true) }
    let!(:deleted_by_receiver) { create(:private_message, :deleted_by_receiver, sender: sender, receiver: receiver) }
    let!(:deleted_by_sender) { create(:private_message, :deleted_by_sender, sender: sender, receiver: receiver) }

    describe ".not_deleted_by_receiver" do
      it "returns messages not deleted by receiver" do
        messages = PrivateMessage.not_deleted_by_receiver
        expect(messages).to include(message1, message2, deleted_by_sender)
        expect(messages).not_to include(deleted_by_receiver)
      end
    end

    describe ".not_deleted_by_sender" do
      it "returns messages not deleted by sender" do
        messages = PrivateMessage.not_deleted_by_sender
        expect(messages).to include(message1, message2, deleted_by_receiver)
        expect(messages).not_to include(deleted_by_sender)
      end
    end

    describe ".for_user" do
      it "returns messages received by user and not deleted by receiver" do
        messages = PrivateMessage.for_user(receiver)
        expect(messages).to include(message1, message2)
        expect(messages).not_to include(deleted_by_receiver)
      end

      it "returns messages sent by user and not deleted by sender" do
        messages = PrivateMessage.for_user(sender)
        expect(messages).to include(message1, message2, deleted_by_receiver)
        expect(messages).not_to include(deleted_by_sender)
      end
    end

    describe ".received_by" do
      let(:test_receiver) { create(:user) }
      let(:test_sender) { create(:user) }

      it "returns messages received by user in descending order" do
        older_message = create(:private_message, sender: test_sender, receiver: test_receiver, created_at: 2.hours.ago)
        newer_message = create(:private_message, sender: test_sender, receiver: test_receiver, created_at: 1.hour.ago)

        messages = PrivateMessage.received_by(test_receiver)
        expect(messages.to_a.first).to eq(newer_message)
        expect(messages.to_a.last).to eq(older_message)
      end

      it "excludes messages deleted by receiver" do
        messages = PrivateMessage.received_by(receiver)
        expect(messages).not_to include(deleted_by_receiver)
      end
    end

    describe ".sent_by" do
      let(:test_sender) { create(:user) }
      let(:test_receiver) { create(:user) }

      it "returns messages sent by user in descending order" do
        older_message = create(:private_message, sender: test_sender, receiver: test_receiver, created_at: 2.hours.ago)
        newer_message = create(:private_message, sender: test_sender, receiver: test_receiver, created_at: 1.hour.ago)

        messages = PrivateMessage.sent_by(test_sender)
        expect(messages.to_a.first).to eq(newer_message)
        expect(messages.to_a.last).to eq(older_message)
      end

      it "excludes messages deleted by sender" do
        messages = PrivateMessage.sent_by(sender)
        expect(messages).not_to include(deleted_by_sender)
      end
    end

    describe ".unread" do
      it "returns only unread messages" do
        messages = PrivateMessage.unread
        expect(messages).to include(message1)
        expect(messages).not_to include(message2)
      end
    end

    describe ".unread_by_user" do
      it "returns unread messages received by user" do
        messages = PrivateMessage.unread_by_user(receiver)
        expect(messages).to include(message1)
        expect(messages).not_to include(message2, deleted_by_receiver)
      end

      it "excludes messages deleted by receiver" do
        unread_but_deleted = create(:private_message, :deleted_by_receiver, sender: sender, receiver: receiver, read: false)
        messages = PrivateMessage.unread_by_user(receiver)
        expect(messages).not_to include(unread_but_deleted)
      end
    end
  end

  describe "Default values" do
    it "sets read to false by default" do
      message = PrivateMessage.new
      expect(message.read).to be false
    end

    it "sets deleted_by_receiver to false by default" do
      message = PrivateMessage.new
      expect(message.deleted_by_receiver).to be false
    end

    it "sets deleted_by_sender to false by default" do
      message = PrivateMessage.new
      expect(message.deleted_by_sender).to be false
    end
  end
end
