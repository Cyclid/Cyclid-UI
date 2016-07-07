module Cyclid; module UI; module Views
class Layout < Mustache
  attr_reader :organization, :linkback_url

  def username
    @current_user.username || 'Nobody'
  end

  def organizations
    @current_user.organizations
  end

  def title
    @title || 'Cyclid'
  end

  # Return an array of elements to be inserted into the breadcrumb
  def breadcrumbs
    @crumbs.to_json
  end
end
end; end; end
