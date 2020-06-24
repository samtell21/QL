module Schmutils
  def self.iter(i, *a, &b)
    Class.new do
      def _ i,a,b
        (a.length + 1 == b.arity) ?
          ->{@i = b.call((@i||=i), *a)} :
          ->(*c){Schmutils.iter(i,*a,*c,&b)}
      end
    end.new._ i,a,b
  end
end