module Utils
#this method requires an entire folder under the lib folder.  Changed the method name trom require_tree
#source:http://74.125.155.132/search?q=cache:iT2I-ir_M1MJ:www.ruby-forum.com/topic/145532+require+statement+rails+folder&cd=1&hl=en&ct=clnk&gl=us
def self.require_folder(name)
      path_to_lib = "{#{RAILS_ROOT}/lib"    #adjust if necessary
      path_to_tree = "#{path_to_lib}/#{name}"
      Dir["#{path_to_tree}/**/*.rb"].each { |fn|
          fn =~ /^#{Regexp.escape(path_to_lib)}\/(.*)\.rb$/
          require $1
      }
end

end