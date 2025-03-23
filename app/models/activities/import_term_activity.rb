module Activities
  class ImportTermActivity < Activity
    include SingleFileTermLists
    include OptList::NoOverride

    def workflow
      []
    end
  end
end
