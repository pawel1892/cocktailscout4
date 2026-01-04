class StaticController < ApplicationController
  skip_authorization_check

  def error_test
    raise 'Bäm! Error!'
  end
end