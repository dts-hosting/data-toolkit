class Activities::ExportRecordId < Activity
  include NoFileRecordType
  include OptList::NoOverride

  def workflow
    []
  end
end
