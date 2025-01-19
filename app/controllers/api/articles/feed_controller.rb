module Api
  module Articles
    class FeedController < Api::Controller
      def phase_invoke
        query = ArticlesQuery.new(params_articles_feed_query)
        if query.invalid?
          return [ query.errors, :bad_request ]
        end

        list = Article.sorted_by_updated_at_desc
                      .joins(:user).where(users: { id: @current_user.following_ids || [] })
                      .offset(query.offset)
                      .limit(query.limit)

        [ res_articles(list), :ok ]
      end

      private
      def params_articles_feed_query
        params.permit(:offset, :limit)
      end

      def res_articles(articles)
        {
          articles: articles.map { |article| article.res({}, @current_user) },
          articlesCount: articles.count
        }
      end
    end
  end
end