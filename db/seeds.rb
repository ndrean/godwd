puts "cleaning"
Event.destroy_all
Itinary.destroy_all
User.destroy_all

puts "creating..."
User.create!(email:"toto@test.fr", password: "password", confirm_email: "true")
User.create!(email:"bibi@test.fr",  password:"password", confirm_email: "true")
# User.create!(email: "nevendrean@yahoo.fr", password:"password")

Itinary.create!(start: "Tibau do sul", end:"Fortaleza", date: Faker::Date.between(from: Date.today, to: '2021-12-01'), start_gps:[-6.2339824, -35.0487455 ], end_gps:[-3.7304512, -38.5217989], distance: 446 )
Itinary.create!(start: "Barranquilla", end:Faker::Address.city, date: Faker::Date.between(from: Date.today, to: '2021-12-01'), start_gps:[10.9799669,-74.8013085 ], end_gps:[10.4195841,-75.5271224] , distance: 82)
Itinary.create!(start: "Soulac s/Mer", end: "Lège-Ca-Ferret", date: Faker::Date.between(from: Date.today, to: '2021-12-01'), start_gps:[45.513149,-1.1228789], end_gps:[44.7245776,-1.2232052], distance: 88)
Itinary.create!(start: "Chichester", end: "Worthing", date: Faker::Date.between(from: Date.today, to: '2021-12-01'))
Itinary.create!(start: "Les Huttes Oléron", end: "Club de Voile, La Palmyre", date: Faker::Date.between(from: Date.today, to: '2021-12-01'), end_gps:[45.68537663874112,-1.1860406398773196], start_gps:[46.010636706068695,-1.393616795539856], distance: 43)
Itinary.create!(start:"Esquibien/St-Evette Audierne FRA", end: "Parking de la Plage Penmarc'h FRA", date:Faker::Date.between(from: Date.today, to: '2021-12-01'), start_gps:[48.00614680866276,-4.556568861007691], end_gps:[47.82499114870398,-4.3578504701145], distance: 25)



a = User.first.id
b = User.last.id


kiters = []
Array(a..b).each { |i| kiters << User.find(i).email}

puts kiters
c= Itinary.first.id
d=Itinary.last.id


Array(c..d).each do |idx|
    id = Array(a..b).sample
    participants = []
    kiters.each { |k| participants << {email: k, notif: true, ptoken:""}}
    Event.create!(user: User.find(id), itinary: Itinary.find(idx), participants: participants)
    
end

puts "done!"
