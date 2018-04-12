require 'rails_helper'

RSpec.describe Category, type: :model do
	describe '无限极分类' do
    # 下面测试运行前都先创建一个名为root1的节点
    before :each do
      @root_category = create(:category)
    end

    it '查看子节点' do
      # 在root_category节点下增加子节点child_category1
      @child_category1 = create(:child_category, parent: @root_category)
      # 在root_category节点下增加子节点child_category1
      @child_category2 = create(:child_category, parent: @root_category)
      # 在root_category1节点下增加子节点child_category11和child_category12
      @child_category11 = create(:child_category, parent: @child_category1)
      @child_category12 = create(:child_category, parent: @child_category1)
      # 根节点里面的子节点数量是 2
      expect(@root_category.children.count).to eq 2
      # 父节点child_category1里面包含child_category11和child_category12
      expect(@child_category1.children).to include @child_category11, @child_category12
    end

    it '查看父节点' do
      # 在root_category节点下增加子节点child_category1
      @child_category1 = create(:child_category, parent: @root_category)
      # 在root_category节点下增加子节点child_category2
      @child_category2 = create(:child_category, parent: @root_category)
      # 在root_category1节点下增加子节点child_category11和child_category12
      @child_category11 = create(:child_category, parent: @child_category1)
      @child_category12 = create(:child_category, parent: @child_category1)
      # child_category11的父节点是child_category1
      expect(@child_category11.parent).to eq @child_category1
      # child_category2的父节点是root_category
      expect(@child_category2.parent).to eq @root_category
    end

    it '查看所有根节点' do
      # 在root_category节点下增加子节点child_category1 
      @child_category1 = create(:child_category, parent: @root_category)
      # 在root_category节点下增加子节点child_category2
      @child_category2 = create(:child_category, parent: @root_category)
      # 在root_category1节点下增加子节点child_category11和child_category12
      @child_category11 = create(:child_category, parent: @child_category1)
      @child_category12 = create(:child_category, parent: @child_category1)
      # 创建root_category2 名字是root2
      @root_category2 = create(:root_category, name: 'root2')
      # 创建root_category3 名字是root3
      @root_category3 = create(:root_category, name: 'root3')
      # Category他的roots根节点数量是3
      expect(Category.roots.count).to eq 3
      # Category里的roots包含了root_category，root_category2，root_category3
      expect(Category.roots).to include @root_category,@root_category2,@root_category3
    end

    it '判断是否是child' do
      # 判断root_category是否是子节点 ，true就是子节点，false就不是子节点
      expect(@root_category.child?).to eq false
      # 在root_category节点下面创建子节点child_category1
      @child_category1 = create(:child_category, parent: @root_category)
      # 判断child是否是子节点，true就是子节点，false就不是子节点
      expect(@child_category1.child?).to eq true
    end

    it '判断是否是root' do
      # 判断 root_category是否是根节点 返回true是根节点，返回false就不是
      expect(@root_category.root?).to eq true
      # 在root_category节点下面创建子节点child_category1
      @child_category1 = create(:child_category, parent: @root_category)
      # 判断child_category1是否是root根节点，是就返回true，返回false就不是
      expect(@child_category1.root?).to eq false
    end
  end
end
