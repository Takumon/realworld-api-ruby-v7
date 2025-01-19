module Api
  module Articles
    module Comments
      class SearchController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            raise ValidationError.new("失敗", :not_found)
          end

          [ res_comments(article.comments, @current_user),  :ok ]
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
