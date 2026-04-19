class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  allow_browser versions: :modern
end
