require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "     "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "     "
    assert_not @user.valid?
  end

  test "name should not be too long" do
    @user.name = "a" * 65
    assert_not @user.valid?
  end

  test "email should not be too long" do
    @user.email = "a" * 257 + "@example.com"
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email addresses should be saved as lower-case" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end

  test "associated messages should be destroyed" do
    @user.save
    @user.messages.create!(content: "Lorem ipsum")
    assert_difference 'Message.count', -1 do
      @user.destroy
    end
  end

  test "should return authentication methods" do
    @user.totp_activated = true
    @user.save
    assert_not_empty @user.multi_factor_methods
  end

  test "should return empty authentication methods list" do
    @user.totp_activated = false
    @user.save
    assert_empty @user.multi_factor_methods
  end

  test "create otp_secret on user creation" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    assert_not_nil new_user.otp_secret
  end

  test "should create new totp" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    new_user.create_totp
    assert_not_nil new_user.totp
  end

  test "should successfully verify current otp with created totp object" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    new_user.create_totp
    current_totp = new_user.totp.now
    assert new_user.totp.verify(current_totp)
  end

  test "should successfully verify current otp with re-created totp object" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    new_user.create_totp
    current_totp = new_user.totp.now
    new_user.create_totp
    assert new_user.totp.verify(current_totp)
  end

  test "should successfully verify current otp with user method" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    assert new_user.verify_totp(ROTP::TOTP.new(new_user.otp_secret).now)
  end

  test "should successfully create keypair" do
    new_user = User.create(name: "Example User", email: "user@example.com",
                           password: "foobar", password_confirmation: "foobar")
    assert_not_nil new_user.public_key && new_user.private_key
  end

end
