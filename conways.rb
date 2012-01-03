require 'gosu'
require 'optparse'

class LifeWindow < Gosu::Window
  CELL_SIZE = 16

  attr_accessor :visible_offset # [x,y] offset of visible viewport
  attr_accessor :occupied_cells # array of [i,j] coordinates that are alive
  attr_accessor :last_mouse_pos # most recent mouse position if clicked
  attr_accessor :circle # circle tile
  attr_accessor :debouncing # array of [i,j] coordinates toggled this right-click

  def initialize
    super(640, 480, false)
    self.caption = "Conway's Game of Life"

    self.visible_offset = [0,0]
    self.occupied_cells = []

    tiles = Gosu::Image.load_tiles(self, "circle.jpg", 16, 16, true)
    self.circle = tiles[0]

    self.debouncing = Hash.new
  end

  def needs_cursor?
    return true
  end

  def draw_grid
    white = Gosu::Color::WHITE
    black = Gosu::Color::BLACK

    self.draw_quad(0, 0, white, self.width, 0, white, self.width, self.height, white, 0, self.height, white, 0)

    grid_offset = self.visible_offset.map { |v| v % CELL_SIZE }
    0.upto(self.width / CELL_SIZE).each do |i|
      x = i * CELL_SIZE + grid_offset[0]
      self.draw_line(x, 0, black, x, self.height, black, 1)
    end
    0.upto(self.height / CELL_SIZE).each do |j|
      y = j * CELL_SIZE + grid_offset[1]
      self.draw_line(0, y, black, self.width, y, black, 1)
    end
  end

  def draw_cells
    self.occupied_cells.each do |i,j|
      x = i * CELL_SIZE
      y = j * CELL_SIZE

      if self.in_bounds?(x, y)
        self.circle.draw(x + self.visible_offset[0], y + self.visible_offset[1], 0)
      end
    end
  end

  def in_bounds?(x, y)
    result = x > -1 * CELL_SIZE - self.visible_offset[0] && x < self.width + CELL_SIZE - self.visible_offset[0] &&
            y > -1 * CELL_SIZE - self.visible_offset[1] && y < self.height + CELL_SIZE - self.visible_offset[1]
    return result
  end

  def draw
    self.draw_grid
    self.draw_cells
  end

  def update
    if self.button_down?(Gosu::Button::MsLeft)
      if !self.last_mouse_pos.nil?
        x_diff = self.mouse_x - self.last_mouse_pos[0]
        y_diff = self.mouse_y - self.last_mouse_pos[1]

        visible_offset[0] += x_diff
        visible_offset[1] += y_diff
      end

      self.last_mouse_pos = [self.mouse_x, self.mouse_y]
    else
      self.last_mouse_pos = nil
    end

    if self.button_down?(Gosu::Button::MsRight)
      coord = self.mouse_to_coord(self.mouse_x, self.mouse_y)
      if self.debouncing[Gosu::Button::MsRight].index(coord).nil?
        if self.occupied_cells.index(coord).nil?
          self.occupied_cells << coord
        else
          self.occupied_cells.delete(coord)
        end
        self.debouncing[Gosu::Button::MsRight] << coord
      end
    else
      self.debouncing[Gosu::Button::MsRight] = []
    end

    if self.button_down?(Gosu::Button::KbC)
      self.clear
    end

    if self.button_down?(Gosu::Button::KbT)
      if self.debouncing[Gosu::Button::KbT] == false
        self.debouncing[Gosu::Button::KbT] = true
        self.tick
      end
    else
      self.debouncing[Gosu::Button::KbT] = false
    end
  end

  def clear
    self.occupied_cells = []
  end

  def tick
    new_occupied = []
    min_max = nil
    if self.occupied_cells.length == 0
      min_max = [[0,0], [0,0]]
    else
      min_max = [self.occupied_cells[0].clone, self.occupied_cells[0].clone]
    end

    self.occupied_cells.each do |i,j|
      min_max[0][0] = i if i < min_max[0][0]
      min_max[1][0] = i if i > min_max[1][0]
      min_max[0][1] = j if j < min_max[0][1]
      min_max[1][1] = j if j > min_max[1][1]
    end

    min_max[0][0] -= 1
    min_max[0][1] -= 1
    min_max[1][0] += 1
    min_max[1][1] += 1

    min_max[0][0].upto(min_max[1][0]).each do |i|
      min_max[0][1].upto(min_max[1][1]).each do |j|
        neighbors = self.neighbors(i,j)
        live_count = neighbors.keep_if{|c| !self.occupied_cells.index(c).nil?}.length
        if live_count == 3
          new_occupied << [i,j]
        elsif live_count == 2 && !self.occupied_cells.index([i,j]).nil?
          new_occupied << [i,j]
        end
      end
    end

    self.occupied_cells = new_occupied
  end

  def neighbors(i,j)
    return [[i-1,j], [i-1,j-1], [i,j-1], [i+1,j-1], [i+1,j], [i+1,j+1], [i,j+1], [i-1,j+1]]
  end

  def mouse_to_coord(x,y)
    return [((x - self.visible_offset[0]) / CELL_SIZE).floor, ((y - self.visible_offset[1]) / CELL_SIZE).floor]
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: conways.rb [options]"

  opts.on("-V", "--version", "Show version info") do |v|
    options[:version] = v
  end
end.parse!

if options[:version]
  puts "Conway's Game of Life, development version"
  puts "License info at http://github.com/lithium3141/Conways"
  Kernel.exit(0)
end

window = LifeWindow.new
window.show
