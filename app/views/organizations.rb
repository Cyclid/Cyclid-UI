class Organizations < Mustache
  def organizations
    @current_user['organizations']
  end
end
