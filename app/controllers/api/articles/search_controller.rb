module Api
  module Articles
    class  SearchController < Api::Controller
      def phase_invoke
        query = ArticlesQuery.new(params_articles_query)
        if query.invalid?
          return [ query.errors, :bad_request ]
        end

        list = Article.sorted_by_updated_at_desc
        if query.author.present?
          list = list.joins(:user).where(user: { username: query.author })
        end

        if query.tag.present?
          list = list.joins(:tags).where(tags: { name: query.tag })
        end

        if query.favorited.present?
          list = list.joins(favorites: :user).where(users: { username: query.favorited })
        end

        list = list.offset(query.offset).limit(query.limit)
        [ res_articles(list), :ok ]
      end


      private

      def params_articles_query
        params.permit(:offset, :limit, :author, :tag, :favorited)
      end

      def res_article(article)
        article.res({ root: true }, @current_user)
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
