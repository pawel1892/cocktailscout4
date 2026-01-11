module AuthenticationHelpers
  def sign_in(user)
    session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")

    # We stub resume_session to bypass the cookie/database lookup and directly set the session
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_wrap_original do |original_method, *args|
      Current.session = session
      session
    end
  end
end
