class Activities::ImportTermActivity < Activity
  include SingleFileTermLists
  include OptList::NoOverride

  def workflow
    []
  end
end
