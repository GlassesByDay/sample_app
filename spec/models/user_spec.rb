require 'spec_helper'

describe User do
  
  # before any further action is taken, this cmmd is exercised
  before { @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar") }

  # identify the 'subject' of all following tests (i.e., it, )
  subject { @user }


  # test that any User object responds to basic attribute calls  
  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:admin) }
  it { should respond_to(:microposts) }

  # test that the object is minimally valid
  it { should be_valid }

  # admin testing
  it { should_not be_admin }

  describe "with admin attribute set to 'true'" do
    before do 
      @user.save!
      @user.toggle!(:admin)
    end

    it { should be_admin }
  end

  # test to make sure remember_token is assigned to user when saved

  describe "remember token" do
    before { @user.save }
    its(:remember_token) { should_not be_blank }
  end

  # basic password check for length  
  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it { should be_invalid }  
  end

  #basic checks for attributes not being blank

  describe "when password is not present" do
    before do
      @user = User.new(name: "Example User", email: "user@example.com", password: " ", password_confirmation: " ")
    end
    it { should_not be_valid }
  end

  describe "when password does not match validation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "when name is not present" do
    before { @user.name = " " }
    it { should_not be_valid }
  end
  
  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end


  # basic check to see if user name is not too long
  describe "when user name is too long" do
    before { @user.name = "x" * 51}
    it { should_not be_valid }
  end


  # authentication test suite for users 
  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by(email: @user.email) }

    describe "with valid password" do
      it { should eq found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }

      it { should_not eq user_for_invalid_password }
      specify { expect(user_for_invalid_password).to be_false }
    end
  end

  # using REGEX to check that email format is valid
  describe "when email format is valid" do
  	it "should be valid" do
  		addresses = %w[user@foo.com A_US-ER@f.b.org first.lst@foo.jp a+b@baz.cn]
  		addresses.each do |valid_address|
  			@user.email = valid_address
  			expect(@user).to be_valid
  		end
  	end
  end

  describe "when email format is not valid" do
  	it "should be invalid" do 
  		addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com, foo@bar..com]
  		addresses.each do |invalid_address|
  			@user.email = invalid_address
  			expect(@user).to_not be_valid
  		end
  	end
  end


  # basic test to make sure username (i.e., email) is not already taken 
  describe "when email address is already taken" do
  	before do
  		user_with_same_email = @user.dup
  		user_with_same_email.email = @user.email.upcase
  		user_with_same_email.save
  	end
  	it { should_not be_valid }
  end

  # test to make sure that usernames (i.e., email addresses) are being properly downcased (!)
  describe "email address with mixed case" do
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

    it "should be saved as all lower case" do
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end
  end

  describe "micropost associations" do

    before { @user.save }
    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end

    it "should have the right microposts in the right order" do
      expect(@user.microposts.to_a).to eq [newer_micropost, older_micropost]
    end

    it "should destroy associated microposts" do
      microposts = @user.microposts.to_a
      @user.destroy
      expect(microposts).to_not be_empty
      microposts.each do |micropost|
        expect(Micropost.where(id: micropost.id)).to be_empty
      end
    end

    describe "status" do
      let(:unfollowed_post) do
        FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
      end

      its(:feed) { should include(newer_micropost) }
      its(:feed) { should include(older_micropost) }
      its(:feed) { should_not include(unfollowed_post) }
    end
  end
end










