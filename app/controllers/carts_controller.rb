class CartsController < ApplicationController
def show
  @cart = Cart.find_by(user_id: current_user.id) 
  user_cart_calculation
end

  def index
    # セッションからカートの情報を取得
    if session[:cart].present?
      # カート内の商品IDを取り出す
      product_ids = session[:cart].map { |item| item["id"] }

      # 商品情報を取得
      @products = Product.where(id: product_ids).index_by(&:id)
    else
      @products = {}
    end
  end

  def add_product
    # 空のカートもしくはカートに商品がない場合は初期化
    session[:cart] ||= []

    # 商品のIDで商品を取得
    product = Product.find(cart_params[:product_id])
    count = cart_params[:count].to_i

    # まだカートに商品がなければ追加
    if session[:cart].none? { |item| item["id"] == product.id }
      session[:cart] << { "id" => product.id, "count" => count }
    else
      # 既に商品がある場合は数量を更新
      item = session[:cart].find { |item| item["id"] == product.id }
      item["count"] += count if item
    end

    cart_calculation
    redirect_to carts_path, notice: '商品がカートに追加されました。'
  end

  def update_quantity
    session[:cart] ||= []

    # 商品のIDを取得
    product_id = params[:id].to_i
    reduce_count = params[:count].to_i

    # カート内の商品を見つける
    item = session[:cart].find { |item| item["id"] == product_id }

    if item
      # 数量を更新
      item["count"] = reduce_count

      # 数量が0になった場合はカートから削除
      if item["count"] <= 0
        session[:cart].delete(item)
        message = '商品がカートから削除されました。'
      else
        message = '数量を更新しました。'
      end
    else
      message = '対象の商品が見つかりませんでした。'
    end

    cart_calculation
    redirect_to carts_path, notice: message
  end

  # カートの商品を削除
  def remove_item
    session[:cart] ||= []
    product_id = params[:id].to_i

    # カートから該当商品を削除
    session[:cart].delete_if { |item| item["id"] == product_id }

    cart_calculation
    redirect_to carts_path, notice: '商品がカートから削除されました。'
  end

  private

  def cart_params
    params.permit(:product_id, :count)
  end
end