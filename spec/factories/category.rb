FactoryBot.define do
	factory :category do
    name  "category"
  end
  factory :root_category, class: Category do
    name  "root_category"
  end

  factory :child_category, class: Category do
    name  "child_category"
  end
end