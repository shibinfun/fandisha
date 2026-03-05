class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :add_to_cart]
  before_action :check_product_visibility, only: [:show]
  
  def index
    # 当前选择的分类（可能来自导航栏的顶级分类或其任一后代）
    if params[:category_id].present?
      @current_category = Category.find_by(id: params[:category_id])
    end

    # 仅展示所选顶级分类这一棵树：
    # 当从 Banner/导航点击顶级分类进入时，只渲染该顶级分类的分支；不显示其他顶级分类。
    if @current_category.present?
      @selected_root = @current_category.path_from_root.first
      @root_categories = Category.where(id: @selected_root.id)
    else
      # 未选择分类时，仍然展示所有顶级分类
      @root_categories = Category.where(parent_id: nil)
    end

    # 构建横向分类导航的各层级集合
    @nav_levels = []
    @nav_levels << @root_categories

    if @current_category
      # 从根到当前节点的路径，逐级把下一层 children 放到导航里
      @current_category.path_from_root.each do |node|
        children = node.children
        @nav_levels << children if children.any?
      end
    end

    # 加载产品：仅限当前选择的分类分支
    if @current_category.present?
      if @current_category.leaf?
        category_ids = [@current_category.id]
      else
        leafs = @current_category.leaf_descendants
        category_ids = leafs.any? ? leafs.map(&:id) : @current_category.self_and_descendant_ids
      end
      @products = Product.visible.where(category_id: category_ids).ordered_by_newest.includes(images_attachments: :blob)
    else
      @products = Product.visible.ordered_by_newest.includes(images_attachments: :blob)
    end
  end
  
  def show
  end
  
  def add_to_cart
    variant = @product.variants.find(params[:variant_id])
    current_cart.add_variant_to_cart(variant)
    redirect_to product_path(@product), notice: "#{@product.name} (#{variant.title}) has been added to cart"
  rescue ActiveRecord::RecordNotFound
    redirect_to product_path(@product), alert: "Please select a valid variant"
  end
  
  private
  
  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found"
  end
  
  def check_product_visibility
    if @product.hidden?
      redirect_to products_path, alert: "This product is currently unavailable"
    end
  end
end
