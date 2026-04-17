namespace :sample do
  GENERATORS = {
    "objectNumber" => -> { 9.times.map { rand(10) }.join },
    "title" => -> { 9.times.map { ("A".."Z").to_a.sample }.join }
  }.freeze

  def generate_csv(fields, count)
    puts fields.join(",")
    count.times do
      puts fields.map { |f| GENERATORS.fetch(f).call }.join(",")
    end
  end

  desc "Generate sample objects CSV to stdout. Usage: rake sample:objects[20000]"
  task :objects, [:count] do |_t, args|
    generate_csv(%w[objectNumber title], Integer(args.fetch(:count, 10)))
  end
end
