module Cyclid; module UI; module Views
class Organizations < Layout
  def organizations
    @current_user.organizations
  end
end
end; end; end
