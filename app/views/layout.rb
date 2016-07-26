require 'digest/md5'

module Cyclid; module UI; module Views
class Layout < Mustache
  attr_reader :organization, :api_url, :linkback_url

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

  # Calculate the base Gravatar URL for the user
  def gravatar_url
    email = @current_user.email.downcase.strip
    hash = Digest::MD5.hexdigest(email)
    "https://www.gravatar.com/avatar/#{hash}?d=identicon&r=g"
  end
end
end; end; end
