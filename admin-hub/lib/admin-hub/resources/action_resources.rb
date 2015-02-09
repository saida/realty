
module AdminHub::Resources
  module ActionController
    #
    # options:
    #  key - model column to search by (default: :id)
    #  only - (default: [:index, :new, :create, :show, :edit, :update, :destroy])
    #  notice - (default: {{model}} was successfully saved!)
    #  permit - permitted fields
    #  weight: false - no weight
    #  datatables:
    #    search: [:title] - search in fields
    #    fields: [:id, :title, lambda {|r| r.title}]
    #    process: -> (row, model) {row << model.id}
    #
    def resources(model, options={})
      instance = new
      all_methods = [:index, :new, :create, :show, :edit, :update, :destroy]

      name = model.model_name.singular.to_s
      methods = Array(options[:only] || all_methods)
      datatables = options[:datatables]
      notice_message = options[:notice] || (model.model_name.human + " was successfully saved!")
      permit = options[:permit]
      belongs = Array(options[:belongs_to]);

      methods.each do |method|
        methods-= [method] if instance_methods.include?(method) #or ([:index].include?(method) and !instance.method_for_action(method.to_s))
      end

      if options[:weight] == false
        has_weight = false
      else
        weight_column = model.columns.find{|p| p.name == "weight"}
        has_weight = weight_column and weight_column.type == :integer
      end
      active_column = model.columns.find{|p| p.name == "active"}
      has_toggle = active_column and active_column.type == :boolean
      has_tags = model.respond_to?("taggable?") and model.taggable?

      define_method :_params do
        if params[name.to_sym]
          p = params.require(name.to_sym)
          unless permit
            res = p.permit!
            if p[:settings] and p[:settings].is_a?(Hash)
              res = res.dup
              res.delete(:settings)
            end
            res
          else
            p.permit(permit)
          end
        else
          {}
        end
      end

      # loaders
      if belongs.present?
        define_method :_load_parents do
          p = nil
          belongs.each do |parent|
            parent_name = parent.to_s.underscore.singularize
            parent = p.method(parent_name.pluralize).call if p
            if parent.respond_to?(:friendly)
              p = parent.friendly.find(params[parent_name + "_id"])
            else
              p = parent.by_key(params[parent_name + "_id"]).first
            end
            raise ActiveRecord::RecordNotFound unless p
            instance_variable_set("@" + parent_name, p)
          end
        end

        define_method :_get_model do
          p = instance_variable_get("@" + belongs[-1].to_s.underscore.singularize)
          p.method(model.model_name.plural).call
        end
        before_filter :_load_parents
      else
        define_method :_get_model do
          model
        end
      end

      define_method :_load_object do
        if params[:id]
          m = _get_model
          if options[:key]
            key = options[:key]
            p = m.find_by((key.is_a?(Proc) ? key.call(params[:id], self) : key).to_s + "=?", params[:id])
          else
            if m.respond_to?(:friendly)
              p = m.friendly.find(params[:id])
            else
              p = m.by_key(params[:id]).first
            end
          end
          raise ActiveRecord::RecordNotFound unless p
          instance_variable_set("@" + name, p)
        end
      end
      before_filter :_load_object, except: [:index, :new]

      # index
      if methods.include?(:index)
        define_method :index do
          if respond_to?(:before_index)
            before_index
            return if response_body
          end
          respond_to do |format|
            format.json do
              mod = _get_model

              # reorder
              if has_weight and params[:reorder]
                from = params[:fromPosition].to_i
                to = params[:toPosition].to_i
                model.transaction do
                  m = mod.find_by_weight(from)
                  if from < to
                    mod.update_all("weight = weight - 1", "weight > %i And weight <= %i" %[from, to])
                  else
                    mod.update_all("weight = weight + 1", "weight >= %i And weight < %i" %[to, from])
                  end
                  m.weight = to
                  m.save
                end
                return render json: {}
              end

              # toggle
              if has_toggle and params[:toggle]
                m = model.find(params[:id])
                m.update(active: !m.active)
                return render json: m.valid? ? m.active : nil
              end
              
              # collection
              if datatables[:collection] || options[:collection]
                p = (datatables[:collection] || options[:collection])
                if p.kind_of?(Symbol)
                  mod = method(p).call(mod)
                elsif p.arity == 1
                  mod = p.call(mod)
                else
                  mod = p.call(self, mod)
                end
              end

              # datatables
              if datatables and params["iDisplayStart"]
                offset = params["iDisplayStart"].to_i
                limit = params["iDisplayLength"].to_i
                limit = 1000 if limit < 0
                total = mod.count
                display = total

                tbl = mod.table_name + "."
                order = datatables[:order]
                if !order and has_weight and params[:with_weight]
                  order = [:weight, :id]
                  if mod.group(tbl + "weight").having("count(*) > 1").exists?
                    model.transaction do
                      mod.select(tbl + "id," + tbl + "weight").order(tbl + "weight," + tbl + "id").each_with_index {|m, i| m.update_column(:weight, i + 1) if m.weight != i + 1}
                    end
                  end
                end

                if !has_weight or params[:no_weight] or !params[:with_weight]
                  order = []
                  (0...params[:iSortingCols].to_i).each do |i|
                    order << (params["iSortCol_#{i}"].to_i + 1).to_s + " " + params["sSortDir_#{i}"]
                  end
                  order = order.join(",")
                end

                mod = mod.select("#{tbl}weight as _weight") if has_weight && params[:with_weight]

                # fields
                attachments = {}
                t = model
                while t && t.respond_to?(:attachment_definitions) do
                  attachments.merge!(t.attachment_definitions)
                  t = t.superclass
                end
                fields = []
                fields = datatables[:fields].dup if datatables[:fields] && !datatables[:fields].kind_of?(Proc)
                if fields.is_a?(Array)
                  fields.each_with_index do |field, index|
                    fields[index] = field.to_s + "_file_name" if attachments.has_key?(field)
                  end
                end
                mod = mod.select(fields + (fields.is_a?(Array) ? ["#{tbl}id"] : ",#{tbl}id"))
                mod = mod.select("#{tbl}active as _active") if has_toggle

=begin
                # collection
                if datatables[:collection] || options[:collection]
                  p = (datatables[:collection] || options[:collection])
                  if p.kind_of?(Symbol)
                    mod = method(p).call(mod)
                  elsif p.arity == 1
                    mod = p.call(mod)
                  else
                    mod = p.call(self, mod)
                  end
                end
=end

                # search
                search = params[:sSearch]
                if datatables[:search] and search
                  search.strip!
                  unless search.empty?
                    if datatables[:search].is_a?(String)
                      cond = datatables[:search]
                    else
                      cond = "lower(" + Array(datatables[:search]).join(" || ") + ") like ?"
                    end
                    mod = mod.where(cond, "%" + search.downcase + "%") unless search.empty?
                    display = mod.count
                  end
                end

                proc = datatables[:fields].kind_of?(Proc) ? datatables[:fields] : datatables[:row]
                aaData = mod.offset(offset).limit(limit).order(order).collect do |row|
                  res = {"DT_RowId" => row.id, "id" => row.id}
                  res["active"] = row._active if has_toggle
                  index = 0
                  row.attribute_names.each do |field|
                    if field.ends_with?("_file_name") and attachments.has_key?(f = field.gsub(/_file_name$/, '').to_sym)
                      t = attachments[f]
                      style = t.has_key?(:index_style) ? t[:index_style] : nil
                      style = :thumb if t[:styles] && t[:styles].kind_of?(Hash) && t[:styles].has_key?(:thumb)
                      res[index] = row.method(f).call.url(style)
                      res[f] = res[index]
                    else
                      res[field] = row[field] if !['DT_RowId', 'id', 'active'].include?(field) && (field.length > 2 || field !~ /^\d+$/)
                      res[index] = row[field]
                    end
                    index+= 1
                  end
                  if proc
                    r = proc.arity == 1 ? proc.call(row) : (proc.arity == 3 ? proc.call(row, res, self) : proc.call(row, res))
                    if r.kind_of?(Hash)
                      r.each{|k, v| res[k] = v}
                    elsif r.kind_of?(Array)
                      if datatables[:fields].kind_of?(Proc)
                        index = has_weight && params[:with_weight] ? 1 : 0
                      end
                      r.each_with_index{|v, i| res[(i + index).to_s] = v}
                    end
                  end
                  res
                end

                render json: {
                  sEcho: params["sEcho"],
                  iTotalRecords: total,
                  iTotalDisplayRecords: display,
                  aaData: aaData
                }
              end
            end
            format.html
          end
        end
      end

      # new
      if methods.include?(:new)
        define_method :new do
          instance_variable_set("@" + name, _get_model.new)
          if respond_to?(:before_new)
            before_new
            return if response_body
          end
          render "edit"
        end
      end

      # create
      if methods.include?(:create)
        define_method :create do
          m = _get_model.new(_params)
          instance_variable_set("@" + name, m)
          
          if respond_to?(:before_create)
            before_create
            return if response_body
          end

          if respond_to?(:before_save)
            before_save
            return if response_body
          end

          if has_weight and m.valid?
            m.weight = 1
            _get_model.update_all("weight = weight + 1")
          end
          if m.save
            if m.respond_to?(:settings) and params[name.to_sym][:settings]
              params[name.to_sym][:settings].each_entry {|k, v| m.settings[k] = v}
            end

            if respond_to?(:after_save)
              after_save
              return if response_body
            end
            respond_to do |format|
              format.json do
                render json: m.to_json
              end
              format.html do
                flash[:notice] = notice_message
                redirect_to action: method_for_action("index") ? :index : :new
              end
            end
          else
            respond_to do |format|
              format.json do
                render json: m.to_json
              end
              format.html do
                render action: :edit
              end
            end
          end
        end
      end

      # show
      if methods.include?(:show)
        define_method :show do
          if respond_to?(:before_show)
            before_show
            return if response_body
          end
          render "show"
        end
      end

      # edit
      if methods.include?(:edit)
        define_method :edit do
          if respond_to?(:before_edit)
            before_edit
            return if response_body
          end
          render "edit"
        end
      end

      # update
      if methods.include?(:update)
        define_method :update do
          m = instance_variable_get("@" + name)
          if respond_to?(:before_update)
            before_update
            return if response_body
          end
          if respond_to?(:before_save)
            before_save
            return if response_body
          end

          result = m.update_attributes(_params)
          if respond_to?(:after_save)
            after_save
            return if response_body
          end
          if result
            if m.respond_to?(:settings) and params[name.to_sym] and params[name.to_sym][:settings]
              params[name.to_sym][:settings].each_entry {|k, v| m.settings[k] = v}
            end
            flash[:notice] = notice_message
            redirect_to action: :edit # method_for_action("index") ? :index : (method_for_action("edit") ? :edit : :show)
          else
            render action: :edit
          end
        end
      end

      # destroy
      if methods.include?(:destroy)
        define_method :destroy do
          m = instance_variable_get("@" + name)
          if respond_to?(:before_destroy)
            before_destroy
            return if response_body
          end
          m.destroy if m
          if respond_to?(:after_destroy)
            after_destroy
            return if response_body
          end
          respond_to do |format|
            format.json do
              render json: m
            end
            format.html do
              redirect_to action: :index if method_for_action("index")
            end
          end
        end
      end
    end

  end
end

ActiveSupport.on_load(:action_controller) do
  extend AdminHub::Resources::ActionController
end
