class LegacyAuthorization < ActiveRecord::Base
  include LegacyBase
  establish_connection "legacy"

  self.table_name = "authorizations"
  # self.primary_key = "old_id"

  # To use autogenerated ids uncomment below
  def dont_migrate_ids
    false
  end

  def migrate_where
    {id: self.id}
  end

  def map
    {
      oauth_provider_id: self.oauth_provider_id,
      user_id: self.user_id,
      uid: self.uid
    }
  end

  def associate
    {
      # association: records.to.associate
    }
  end

end