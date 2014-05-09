module GitReview

  class Repository

    include Accessible

    attr_accessor :owner,
                  :name

  end

end
