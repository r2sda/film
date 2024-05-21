require 'net/http'
require 'json'
require 'uri'
require 'dotenv/load'

# Список возможных настроений
MOODS = {
  "грустно" => ["драма", "мелодрама"],
  "весело" => ["комедия", "приключения"],
  "страшно" => ["ужасы", "триллер"],
  "задумчиво" => ["фантастика", "драма", "детектив"],
  "мотивированно" => ["биография", "спорт"],
  "расслабленно" => ["комедия", "мультфильм", "семейный"]
}

# Функция для получения популярных фильмов
def get_popular_films
  begin
    url = URI("https://kinopoiskapiunofficial.tech/api/v2.2/films/top?type=TOP_100_POPULAR_FILMS&page=1")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["X-API-KEY"] = ENV['KINOPOISK_API_KEY']
    request["Content-Type"] = "application/json"

    response = http.request(request)
    if response.code == "200"
      return JSON.parse(response.body)["films"]
    else
      puts "Ошибка API: #{response.code} - #{response.message}"
      return []
    end
  rescue => e
    puts "Ошибка при получении данных: #{e.message}"
    return []
  end
end

# Функция для получения детальной информации о фильме
def get_film_details(film_id)
  begin
    url = URI("https://kinopoiskapiunofficial.tech/api/v2.2/films/#{film_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["X-API-KEY"] = ENV['KINOPOISK_API_KEY']
    request["Content-Type"] = "application/json"

    response = http.request(request)
    if response.code == "200"
      return JSON.parse(response.body)
    else
      puts "Ошибка API: #{response.code} - #{response.message}"
      return {}
    end
  rescue => e
    puts "Ошибка при получении данных о фильме: #{e.message}"
    return {}
  end
end

# Функция для выбора фильма по настроению
def suggest_film_by_mood(mood)
  if MOODS.key?(mood)
    desired_genres = MOODS[mood]
    popular_films = get_popular_films

    if popular_films.empty?
      puts "Не удалось получить список популярных фильмов. Попробуйте позже."
      return nil
    end

    suitable_films = []

    # Проверяем до 15 фильмов, чтобы не делать слишком много запросов
    popular_films.first(15).each do |film|
      film_details = get_film_details(film["filmId"])
      next if film_details.empty?

      film_genres = film_details["genres"].map { |g| g["genre"].downcase }

      if (desired_genres & film_genres).any?
        suitable_films << {
          title: film_details["nameRu"],
          original_title: film_details["nameOriginal"],
          year: film_details["year"],
          countries: film_details["countries"].map { |c| c["country"] }.join(", "),
          genres: film_details["genres"].map { |g| g["genre"] }.join(", "),
          rating: film_details["ratingKinopoisk"],
          description: film_details["description"],
          poster: film_details["posterUrl"],
          kinopoisk_id: film_details["kinopoiskId"]
        }
      end
    end

    if suitable_films.empty?
      puts "К сожалению, не удалось подобрать фильм по вашему настроению."
      return nil
    end

    return suitable_films.sample
  else
    puts "Неизвестное настроение. Пожалуйста, выберите из списка: #{MOODS.keys.join(', ')}"
    return nil
  end
end

# Основная логика программы
def main
  puts "Привет! Я посоветую тебе фильм."
  puts "Какое у тебя сегодня настроение? Выбери из списка: #{MOODS.keys.join(', ')}"
  mood = gets.chomp.downcase

  film = suggest_film_by_mood(mood)

  if film
    puts "\nПредлагаю посмотреть: #{film[:title]}"
    puts "(#{film[:original_title]})" if film[:original_title] && film[:original_title] != film[:title]
    puts "Год выпуска: #{film[:year]}"
    puts "Страна: #{film[:countries]}"
    puts "Жанр: #{film[:genres]}"
    puts "Рейтинг Кинопоиска: #{film[:rating]}/10" if film[:rating]
    puts "\nОписание: #{film[:description]}" if film[:description]
    puts "\nПостер: #{film[:poster]}" if film[:poster]
    puts "Подробнее: https://www.kinopoisk.ru/film/#{film[:kinopoisk_id]}/"
  end
end

# Запускаем программу
main
