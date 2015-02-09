class UsersController < ApplicationController
  resources User,
    datatables: { 
      search: [:username, :email],
      fields: [:username, :email]
    },
    notice: 'Пользователь успешно сохранен.'
end
