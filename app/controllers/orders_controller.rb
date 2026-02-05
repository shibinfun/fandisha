class OrdersController < ApplicationController
  before_action :check_cart_not_empty, only: [:new, :create]
  
  def new
    @cart = current_cart
    @order = @cart.build_order
  end
  
  def create
    @cart = current_cart
    @order = @cart.build_order(order_params)
    
    if @order.save
      # 清空购物车
      @cart.cart_items.destroy_all
      session[:cart_id] = nil
      
      # 存储订单ID到session用于待支付提醒
      session[:pending_order_id] = @order.id
      
      redirect_to order_path(@order), notice: "Order created successfully! Order #: #{@order.id}"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    @order = Order.find(params[:id])
  end
  
  private
  
  def order_params
    params.require(:order).permit(:name, :email, :phone, :address)
  end
  
  def check_cart_not_empty
    if current_cart.cart_items.empty?
      redirect_to cart_path, alert: "购物车是空的，请先添加商品"
    end
  end
end
