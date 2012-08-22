# encoding: utf-8
class UsersMailer < ActionMailer::Base
  default :from => "\"Júlio Santos\" <hi@whoisjuliosantos.com>"

  def friends_likes_email (user)
    @unicorns = user.unicorns?
    mail({
      :to => user.email,
      :subject => "#{user.name}, your friends' likes are ready!"
    })
  end
end
