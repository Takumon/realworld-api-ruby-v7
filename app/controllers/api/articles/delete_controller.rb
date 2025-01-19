module Api
  module Articles
    class DeleteController < Api::Controller
      def phase_invoke
        article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

        if article.nil?
          raise ValidationError.new("失敗", :not_found)
        end

        unless article.destroy
          raise ValidationError.new("失敗", :unprocessable_entity)
        end

        [ {},  :ok ]
      end

      private
      # nothing
    end
  end
end
