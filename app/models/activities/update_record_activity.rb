class Activities::UpdateRecordActivity < Activity
  include SingleFileRecordType
  include OptList::AllowOverride

  def workflow
    []
  end
end
