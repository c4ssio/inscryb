class User < ActiveRecord::Base
  has_many :clipboard_members

# Checks login information
  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user.nil?
      #create a new user
      user = self.create(:name=>name, :password=>password)
    elsif Password::check(password,user.password)
      #return the found user
      user
    else
      return false
    end
  end

  protected

  # Hash the password before saving the record
  def before_create
    self.password = Password::update(self.password)
  end

end
