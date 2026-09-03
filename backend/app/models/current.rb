# Request-scoped state: who is signed in, and which site the request belongs to.
#
# The public renderer and the admin API both need the current site, and passing
# it down through every object would bury the actual logic in plumbing.
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :site, :request_id, :user_agent, :ip_address

  def user = session&.user
end
