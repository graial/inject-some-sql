class ProductsController < ApplicationController
  # Fragment-caching example: the cached fragment is keyed off the product
  # record itself (see views/products/show.html.erb).
  def show
    @product = Product.find(params[:id])
  end
end
