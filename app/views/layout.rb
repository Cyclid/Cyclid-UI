module Cyclid; module UI; module Views
class Layout < Mustache
  def username
    @current_user.username || 'Nobody'
  end

  def organizations
    @current_user.organizations
  end

  def title
    @title || 'Cyclid'
  end
end
end; end; end
