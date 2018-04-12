class Category
  include Mongoid::Document
  # include Mongoid::Tree
  field :name, type: String
  has_many :children, class_name: 'Category', inverse_of: :parent

  belongs_to :parent, class_name: 'Category', inverse_of: :children
  # 判断是否是字节点
  def child?
  # 当前自己的父节点不为空
    self.parent != nil
  end
  # 判断是否是父节点
  def root?
  # 当前自己的父节点等于空
    self.parent == nil
  end
  # 拿到自己的所有父节点
  def self.roots
  # 自己里面父节点等于空的就是父节点
    where(parent: nil)
  end
  # 拿到所有的子节点
  def self.children
  # 
    where(:parent.ne => nil)
  end
end
