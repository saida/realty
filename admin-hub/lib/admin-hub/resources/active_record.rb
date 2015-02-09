module AdminHub::Resources
  module ActsAsParam
    def key keyname=nil
      @key = keyname if keyname
      @key || 'id'
    end

    def by_key(value)
      self.where((@key || :id) => value)
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend AdminHub::Resources::ActsAsParam
end
