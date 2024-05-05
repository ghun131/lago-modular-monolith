class PublisherPortalRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :publisher_portal }
end
