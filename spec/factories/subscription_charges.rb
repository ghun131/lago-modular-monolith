FactoryBot.define do
  factory :subscription_charge do
    id { "" }
    plan_title { "MyString" }
    subscription_instance_id { 1 }
    is_finalized { false }
  end
end
