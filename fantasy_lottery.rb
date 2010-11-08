
class LotteryDraw
  @@tickets, @@standard = {}, {}
  def initialize( customer, *tickets )
    if @@tickets.has_key? customer
      tix = @@tickets[customer]
    else
      tix = {}
    end
    tickets.each do |ticket|
      tix[ticket.gd.name] ||= []
      tix[ticket.gd.name] << ticket
      next if @@standard.has_key? ticket.gd.name
      @@standard[ticket.gd.name] = LotteryTicket.new(LotteryGame.new(ticket.gd.name, ticket.gd.components))
    end
    @@tickets[customer] = tix
  end
  def play
    winners = {}
    @@tickets.keys.each do |cust_name| 
      @@tickets[cust_name].keys.each do |game_name|
        @@tickets[cust_name][game_name].each do |ticket|
          next if not ticket.is_winner? @@standard[game_name]
          winners[@@standard[game_name]] ||= []
          winners[@@standard[game_name]] << [cust_name, ticket]
        end
      end
    end
    @@tickets.clear
    pretty_print_results(winners)
  end
  def set_winning(*tickets)
    tickets.each do |ticket|
      @@standard[ticket.gd.name] = ticket
    end
  end
  def pretty_print_results(a_hash)
    a_hash.keys.each do |std_tik|
      puts "#{std_tik.gd.name} winning numbers:"
      puts "#{std_tik.picks.join(', ')}"
      a_hash[std_tik].each do |buyer, a_play|
        puts "\t#{buyer}:"
        puts "#{a_play.picks.join(', ')}"
      end
      puts
    end
  end
end

class LotteryGame
  attr_reader :name, :components
  def initialize(name, components)
    @name = name
    @components = components
  end
end

class LotteryTicket
  attr_reader :num_seq_array, :picks, :purchased, :gd
  def initialize( game_definition, *picks )
    @purchased = Time.now.strftime("%d%b%Y%a %I:%M%p %Z").upcase
    @gd = game_definition
    @num_components = @gd.components.length
    @winning_floor = []
    @gd.components.each {|gd_c| @winning_floor << gd_c[-1]}
    if picks.length > 0
      @quickpick = true
      @num_seq_array = []
      user_input = picks.dup
      @elements_per_array = @gd.components.transpose[1]
      @elements_per_array.each {|num| @num_seq_array << user_input.slice!(0..(num-1))}
      @picks = picks
    else
      @quickpick = false
      @num_seq_array = @gd.components.collect {|max_range, num_draws| Numeric_Sequence_Generator.new_quickpick(max_range, num_draws).picks.sort }
      @picks = @num_seq_array.flatten
    end
  end
  def score(self_component, component_from_standard_ticket)
    count = 0
    component_from_standard_ticket.each {|standard_num| count += 1 if self_component.include? standard_num}
    count
  end
  def is_winner?(standard_ticket)
    (0...@num_components).each do |index|
      return true if score(@num_seq_array[index], standard_ticket.num_seq_array[index]) >= @winning_floor[index]
    end
    return false
  end
  def quickpick?
    @quickpick
  end
end

class Numeric_Sequence_Generator
  attr_reader :picks
  def initialize(max_range, num_draws, *picks)
    @max_range = max_range
    @num_draws = num_draws
    numeric_range = 1..@max_range
    if picks.length != num_draws
      raise ArgumentError, "You need to supply me with #{@num_draws} numbers, dogg."
    elsif picks.uniq.length != num_draws
      raise ArgumentError, "You need to supply #{@num_draws} different numbers, yo."
    elsif picks.detect { |p| not numeric_range === p }
      raise ArgumentError, "Your #{@num_draws} different numbers can only be 1 through #{@max_range}, mi hermano negrito."
    end
    @picks = picks
  end
  def self.new_quickpick(max_range, num_draws)
    an_array = []
    num_draws.times {an_array << eval("rand(#{max_range})+1")}
    new(max_range, num_draws, *an_array)
    rescue ArgumentError
      retry
  end
end
