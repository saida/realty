class ExceptionController < ActionController::Base

  def error
    layout = 'application'
    @exception = env["action_dispatch.exception"]
    @status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    if @exception.is_a?(StandardError) and @exception.message == "unsupported_browser"
      @title = Settings.browser_error_title
      @body = Settings.browser_error_body
      @status_code = 200
      layout = "exception"
    elsif @status_code == 404
      @title = Settings.page_not_found_title
      @body = Settings.page_not_found_body
    elsif @status_code == 500
      @title = "We're sorry, but something went wrong (500)"
      @body = "If you are the application owner check the logs for more information."
    end
    render status: @status_code, layout: layout
  end
end
