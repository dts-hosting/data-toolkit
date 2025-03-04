class Activities::AnalyzeMediaActivity < Activity
  include MultiFileRecordType
  include OptList::NoOverride

  def workflow
    []
  end
end
