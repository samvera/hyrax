class DatabaseChecker
  def call(env)
    ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }
  rescue => error
    ApplicationController::render_500(error)
  end
end
