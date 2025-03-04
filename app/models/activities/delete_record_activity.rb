class Activities::DeleteRecordActivity < Activity
  include SingleFileRecordType
  include OptList::NoOverride

  def workflow
    []
  end
end
