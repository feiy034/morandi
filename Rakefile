#desc 'Watch coffeescript for changes'
#task :watch do
#  system 'coffee', '-w', '-c', *Dir['lib/*.coffee']
#end

require 'coffee-script'
require 'pathname'
def load_file(fn, paths, output)
  paths.each { |dir|
    path = Pathname.new(dir).join(fn)
    next unless path.exist?
    
    IO.readlines(path.to_s).each do |line|
      case line
      when %r'^(#|//)= ([^\s]*)'
        load_file($2, paths, output)
      else
        if output.last && output.last.has_key?(:script) && output.last[:path] == path.to_s
          output.last[:data] << line
        else
          output << { :script => path.basename, :path => path.to_s, :ext => path.extname, :data => line }
        end
      end
    end
  }
  output
end

# returns filenames
def compile(fn, paths, target)
  result = load_file(fn, paths, [])
  data = result.map do |entry|
    if entry[:ext] == '.coffee'
      "// file: #{entry[:script]}\n " +
      CoffeeScript.compile(entry[:data])
    elsif entry[:ext] == '.js'
      "// file: #{entry[:script]}\n " +
      entry[:data]
    else
      raise "Unrecognised file format: #{ entry[:script]} }"
    end
  end * ""

  File.open(target, 'w') { |fp| fp << data }

  result.map { |entry| entry[:path] }
end

def compile_default
  compile('morandi.js.coffee', [File.join(File.dirname(__FILE__),'src')], 'lib/morandi.js') 
end

desc 'Compile FTW'
task :compile do
  compile_default
end


def watch(notifier, path)
  @known ||= {}
  return if @known[path]
  puts "Watching #{path}"
  notifier.watch(path, :create, :modify, :close_write) { |event| puts "#{event.absolute_name} changed"; @known.delete(event.absolute_name); compile_default.each { |pth| watch(notifier, pth) } }
  @known[path] = true
end
desc 'Watch & compile'
task :watch do
  require 'rb-inotify'
  $known = {}
  notifier =  INotify::Notifier.new
  compile_default.each { |path| watch(notifier, path) }
  notifier.run
end
