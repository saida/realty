class CategoriesController < ApplicationController
  resources Category,
    datatables: {
      collection: -> (c) { c.select(:name, :slug, :un).includes(:category_items) },
      fields: -> (row) { [row.name, row.category_items.count, row.slug, row.un] }
    },
    notice: 'Категория успешно сохранена.'
  
  def before_new
    3.times { @category.category_items.build }
  end
  
  def before_edit
    if @category.category_items.blank?
      3.times { @category.category_items.build }
    end
  end
  
  def before_index
    expire_fragment(/filter-.*/)
  end
end
