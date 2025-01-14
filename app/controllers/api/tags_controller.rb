class Api::TagsController < ApplicationController
  before_action :authenticate_request, except: [ :index ] # 認証不要

  def index
    render json: { tags: Tag.all.map(&:name) }
  end
end
