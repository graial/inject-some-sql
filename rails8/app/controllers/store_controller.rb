class StoreController < ApplicationController
  # Russian-doll caching example: the outer `cache @products` fragment wraps
  # one `cache product` fragment per row (see views/store/index.html.erb).
  #
  # When ?q= is present, the product list comes from Product.cached_search -
  # the (deliberately unsafe) low-level caching example. Its SQL isn't bound
  # to a fixed column set, so results are read back defensively.
  def index
    @products =
      if params[:q].present?
        Product.cached_search(params[:q]).filter_map do |row|
          Product.new(id: row["id"], title: row["title"], price: row["price"])
        rescue ActiveModel::UnknownAttributeError
          nil
        end
      else
        Product.order(:title)
      end
  end
end
