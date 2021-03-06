require 'test_helper'

class UINotificationsHostsTest < ActiveSupport::TestCase
  class TestNotification < ::UINotifications::Hosts::Base
    def create
      ::Notification.create!(
        initiator: initiator,
        subject: subject,
        audience: audience,
        notification_blueprint: blueprint
      )
    end

    def blueprint
      @blueprint ||= FactoryGirl.create(:notification_blueprint)
    end
  end

  test 'notification audience should be SUBJECT if owner is present' do
    host.owner = FactoryGirl.build(:user)
    assert_equal 'subject', audience
  end

  test 'notification audience should be nil if there is no owner' do
    host.owner = nil
    assert_nil audience
  end

  test 'deliver! should not run if audience is nil' do
    host.owner = nil
    assert !base.deliver!
  end

  describe 'deliver notification to host owner' do
    test 'owner is single user' do
      host.owner = FactoryGirl.create(:user)
      assert_difference("NotificationRecipient.all.count", 1) do
        assert TestNotification.new(host).deliver!
      end
    end

    test 'owner is usergroup' do
      group = FactoryGirl.create(:usergroup)
      group.users = FactoryGirl.create_list(:user, 5)
      host.owner = group
      assert_difference("NotificationRecipient.all.count", 5) do
        assert TestNotification.new(host).deliver!
      end
    end
  end

  private

  def host
    @host ||= FactoryGirl.build(:host, :managed)
  end

  def base
    UINotifications::Hosts::Base.new(host)
  end

  def audience
    base.send(:audience)
  end
end
