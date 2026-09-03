module Api
  # First run: the installation has no accounts yet.
  #
  # This is the one endpoint that answers before anybody has signed in, which is
  # why it closes the moment an owner exists. Otherwise a server that sat idle
  # for a day would let a passer-by claim it.
  class SetupsController < ApplicationController
    skip_before_action :require_authentication, raise: false

    def show
      render json: { needs_setup: User.none?, admin_url: Yulia.admin_url }
    end

    def create
      return render json: { error: "already_set_up" }, status: :conflict if User.any?

      user = User.new(setup_params.merge(role: "owner"))

      if user.save
        sign_in(user)
        render json: { user: serialize(user), next: "enrol_second_factor" }, status: :created
      else
        render json: { error: "invalid", messages: user.errors.full_messages },
               status: :unprocessable_content
      end
    end

    private

      def setup_params
        params.expect(setup: [ :email, :name, :password, :password_confirmation ])
      end

      def serialize(user)
        { id: user.id, email: user.email, name: user.name, role: user.role,
          second_factor_enrolled: user.second_factor_enrolled? }
      end
  end
end
