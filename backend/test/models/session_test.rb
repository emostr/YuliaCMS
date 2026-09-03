require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = create_user
  end

  test "stores only a digest, never the token itself" do
    session, token = Session.start!(user: @user)

    assert_not_equal token, session.token_digest
    assert_nil Session.find_by(token_digest: token)
    assert_equal session, Session.authenticate(token)
  end

  test "refuses an expired session" do
    session, token = Session.start!(user: @user)
    session.update!(expires_at: 1.minute.ago)

    assert_nil Session.authenticate(token)
  end

  test "refuses a blank or unknown token" do
    assert_nil Session.authenticate(nil)
    assert_nil Session.authenticate("")
    assert_nil Session.authenticate("made-up")
  end

  test "sweeping removes only what has lapsed" do
    live, = Session.start!(user: @user)
    stale, = Session.start!(user: @user)
    stale.update!(expires_at: 1.day.ago)

    Session.sweep!

    assert Session.exists?(live.id)
    assert_not Session.exists?(stale.id)
  end
end
