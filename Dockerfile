# Используем базовый образ с поддержкой Ruby
FROM ruby:2.7

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app
# Устанавливаем Bundler
RUN gem install bundler:2.2.33

# Копируем Gemfile и Gemfile.lock в контейнер
COPY Gemfile Gemfile.lock /app/

# Устанавливаем зависимости приложения
RUN bundle install

# Копируем остальные файлы в контейнер
COPY . /app/

# Экспортируем порт, который будет использоваться приложением
EXPOSE 4567

# Команда для запуска приложения при старте контейнера
CMD ["ruby", "route.rb"]

