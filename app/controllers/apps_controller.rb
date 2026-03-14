class AppsController < ApplicationController
  before_action :set_app, only: %i[show edit update destroy]

  def index
    @apps = App.order(:name).page(params[:page])
  end

  def show
  end

  def new
    @app = App.new
  end

  def edit
  end

  def create
    @app = App.new(app_params)

    if @app.save
      redirect_to @app, notice: "App was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @app.update(app_params)
      redirect_to @app, notice: "App was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @app.destroy!
    redirect_to apps_path, notice: "App was successfully deleted.", status: :see_other
  end

  private

  def set_app
    @app = App.find(params.expect(:id))
  end

  def app_params
    params.expect(app: [:name, :description, :github_repository, :url])
  end
end
