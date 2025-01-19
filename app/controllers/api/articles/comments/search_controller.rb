module Api
  module Articles
    module Comments
      class SearchController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            render json: "失敗", status: :not_found
            return
          end

          render json: res_comments(article.comments, @current_user), status: :ok
        end

        private
        def res_comments(comments, target_user)
          {
            comments: comments.map { |c| c.res({}, target_user) }
          }
        end
      end
    end
  end
end
