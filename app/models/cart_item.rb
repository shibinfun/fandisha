class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant
  
  has_one :product, through: :product_variant
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :product_variant_id, uniqueness: { scope: :cart_id, message: "already in cart" }
  
  # 小计（单个 CartItem 的总价）
  def subtotal
    product_variant.price * quantity
  end
end
