class ApplicationController < ActionController::API
  def sample
    print "print直後に2個以上の半角スペースを記述するとRubocopのエラーが発生する"
  end
end
