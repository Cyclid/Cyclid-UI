class SomeCSRFForm < Mustache
  def csrf_tag
    # @env is a local, passed as:
    #
    # mustache :somecsrfform, locals: env
    Rack::Csrf.csrf_tag(@env)
  end

  # Or alternatively:
  include Cyclid::UI::Helpers

  def csrf
    csrf_tag(@env)
  end
end
