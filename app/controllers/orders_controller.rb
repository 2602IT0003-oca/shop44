class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart, only: [:new, :confirm, :create]

  # 注文履歴一覧
  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  # 注文画面
  def new
    if @cart.blank? || @cart.cart_items.empty?
      redirect_to cart_path(@cart || current_user.cart), alert: "カートに商品が入っていません。"
      return
    end

    @order = Order.new
    set_cart_summary
  end

  # 注文内容の確認画面
  def confirm
    if @cart.blank? || @cart.cart_items.empty?
      redirect_to cart_path(@cart || current_user.cart), alert: "カートに商品が入っていません。"
      return
    end

    set_cart_summary

    @order = Order.new(
      address: order_params[:address],
      user: current_user,
      total_price: @cart_total
    )

    unless @order.valid?
      render :new, status: :unprocessable_entity
    end
  end

  # 注文登録
  def create
    if @cart.blank? || @cart.cart_items.empty?
      redirect_to cart_path(@cart || current_user.cart), alert: "カートに商品が入っていません。"
      return
    end

    set_cart_summary

    @order = current_user.orders.build(
      address: order_params[:address],
      total_price: @cart_total
    )

    ActiveRecord::Base.transaction do
      @order.save!

      @cart_items.each do |item|
        @order.order_details.create!(
          product_id: item.product.id,
          quantity: item.quantity,
          price: item.product.price
        )
      end

      @cart.cart_items.destroy_all
    end

    redirect_to complete_order_path(@order)
  rescue ActiveRecord::RecordInvalid => e
    @order.errors.add(:base, e.record.errors.full_messages.join(", ")) if @order.errors.empty?
    render :new, status: :unprocessable_entity
  end

  # 注文完了
  def complete
    @order = Order.find(params[:id])
    @total_price = @order.total_price || @order.order_details.sum { |d| (d.price || d.product.price) * d.quantity }
  end

  private

  def set_cart
    @cart = current_user.cart
  end

  def set_cart_summary
    @cart_items = @cart.cart_items.includes(:product)
    @item_totals = @cart_items.map { |item| item.product.price * item.quantity }
    @cart_total = @item_totals.sum
    @total_price = @cart_total
    @order.total_price = @cart_total if @order.present?
  end

  def order_params
    params.require(:order).permit(:address)
  end
end