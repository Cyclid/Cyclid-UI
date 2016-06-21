module Cyclid; module UI; module Views
class Organization < Layout
  def name
    @org['name']
  end

  def owner
    @org['owner_email']
  end

  def users
    @org['users']
  end

  def public_key
    @org['public_key']
  end
end
end; end; end
