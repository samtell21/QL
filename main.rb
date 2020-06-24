s= "1.:116,3:1:6,7;2:3,4,5;;41:0,4;601;2.:107,2:0:5,9;16;4:0:2,7:A,B,C;;13;5:08,13;609,70:2,5,7;8:0:1,2,3,4,5,6,7,8,9;1:0,3;;9:0:1-3,9;1:1-9;;;3.:10:2,5,6,7;20:2,4;50:3,6,7,8,9;6:08,1:0,1:,A;2,3,4;;7:09,1:0,3;;;"

require_relative 'rem'
require_relative 'iter'
require_relative 'misc'

module Shorthand
    
    @sym = 
            [
                '\*',#0
                '\-',#1
                '\+',#2
                '\^',#3
                '\<',#4
                '\?(\w)\|(.*?)\?',#5
                '=(\d+)=',#6
                '&',#7
                '\(',#8
            ]
    
    @@iv = instance_variables
    class<<self
        @@iv.each{|v| attr_reader Schmutils.noat(v)}
        
        
        def form a
            a.to_s[1..-2].gsub(/"| /,"")
        end
        
        def expand s
            
            while (r ||= /(\w+?)-(\w+)/).match(x ||= s.clone)
                x.sub!(r, form(eval("'#{$1}'..'#{$2}'").to_a))
            end
            x
        end
        
        def hashit s
            eval "{"+ 
                    expand(s)
            .gsub(/:/, "=>{")
            .gsub(/;(?=;|\z)/, "}")
            .gsub(/;/,"},")
            .gsub(/(?<!})(?=[,}])/,"=>nil")
            .gsub(/(?<=^|[{,]).*?(?==>)/m,'"\0"') +"}"
        end
        
        def items s
            aux = ->(h) do
                h.map do |k,v|
                    v ? aux.(v).map{|e| k+e} : [k]
                end.flatten
            end
            aux.call hashit(s)
        end
        
        
        using Remmable
        def is s
            sym = ['\*','\-','\+','\^','\<','\?(\w)\|(.*?)\?','=(\d+)=','&']
            m =  sym.join('|')
            mb = /^(#{m})/
            me = /(#{m})$/
            
            a = expand(s).split(',').map do |e| 
                [
                    e.remall(mb).remss, 
                    e.remall(me).remsult, 
                    e.remfresh.remall(me).remss
                ]
            end
            
            
            
            
            o = []
            e = []
            catch(:"a") do
                a.each do |pre, v, post|
                    catch(:"1") do
                        off = -1
                        catch(:nomatch) do 
                            loop do
                                #p "#{pre}, #{v}, #{post}"
                                v.rem(/\\l(\d+)(!)?\\/, true, throws: true) #/)
                                v = v.remd[2] ?
                                v.rar.join(e[-v.remd[1].to_i].to_s) :
                                v.rar.join(o[-v.remd[1].to_i])
                            end
                        end
                        catch(:nomatch) do 
                            loop do
                                #p "#{pre}, #{v}, #{post}"
                                v.rem(/\\f(\d+)(!)?\\/, true, throws: true) #/)
                                
                                v = v.remd[2] ?
                                v.rar.join(e[v.remd[1].to_i].to_s) :
                                v.rar.join(o[v.remd[1].to_i])
                            end
                        end
                        
                        #v.gsub!(/\\l/, o[-1]||'')
                        l = v.length
                        del,prefix=nil
                        pre.each do |p|
                            sym1 = sym.map{|e| Regexp.new e}
                            case p
                            when sym1[0] # *
                                l=0
                            when sym1[1] # -
                                l+=1
                            when sym1[2] # +
                                l-=1
                            when sym1[3] # ^
                                del = true
                            when sym1[4] # <
                                prefix=true
                            when sym1[5] # ?(...)?
                                p1 = sym1[5].match(p)[1].to_sym
                                p2 = sym1[5].match(p)[2]
                                case p1
                                when :b
                                    break
                                when :"1", :a
                                    throw p1
                                end if(eval p2)
                            when sym1[6] # =(...)=
                                off = sym1[6].match(p)[1].to_i
                            when sym1[7]
                                l+=o[off].length
                            end
                        end
                        y = o[off] || ""
                        x = (prefix ?
                             (v+y[(0+l)..-1])  :
                            (y[0..(-1-l)]+v))
                        o.delete_at(off) if del
                        e.delete_at(off) if del
                        o<< x
                        begin
                            e<< eval(x) 
                        rescue Exception 
                            e<< nil
                        end
                    end
                end
            end
            
            o
            
        end
        #####################################################################################################
        def ex s
            m =  "!.*!|"+sym.join('|')
            mb = /^(#{m})/
            me = /(?<!\\)(\))$/
            
            while (r ||= /(\w+?)-(\w+)/).match(x ||= s.clone)
                x.sub!(r, form(eval("'#{$1}'..'#{$2}'").to_a))
            end
            x.split(',').map do |e| 
                [
                    e.remall(mb).remss, 
                    e.rem(me).remsult, 
                    e.remd.to_s
                ]
            end
        end
        
        def ineval s, v
            s = s.remset.rem /(?<=^!)(.*)(?=!$)/
            throw s.to_sym unless s.remd
            (s.remd[1][0] == ' ') ? 
                eval(s.remd[1].gsub(/_/, v)) :
                newis(s.remd[1].gsub(/_/, v).gsub(/;/,','))[-1]
        end
        
        def newis s
            
            sym1 = sym.map{|e| Regexp.new e}
            
            a = ex(s)
            
            o=[]
            paren = []
            catch(:a) do
                a.each do |pre,v,post|
                    catch(:"1") do
                        off = -1
                        v = backref(v, o)
                        l = v.length
                        del,prefix = nil
                        
                        pre.prepend(paren).flatten!
                        work = []
                        pre.each do |p|
                            case p
                            when '('
                                paren = work
                                work = []
                            else
                                
                                work << p
                                case p
                                when '*'
                                    l=0
                                when '-'
                                    l+=1
                                when '+'
                                    l-=1
                                when '^'
                                    del = true
                                when '<'
                                    prefix = true
                                when /^\?.+\?$/
                                    p1 = sym1[5].match(p)[1]
                                    p2 = eval(sym1[5].match(backref(p,o))[2])
                                    ineval(p1,v) if p2
                                when '&'
                                    x = o.map{|e| e[0]}
                                    l+= x.max_by(&:length).to_s.length
                                when Regexp.new("!.*!")
                                    v = ineval(p,v).to_s
                                end
                            end
                        end
                        if post == ')'
                            paren = []
                        end
                        
                        y = o[off] || " "
                        x = (y[0][0..(-1-l)]+v)

                        o.delete_at(off) if del
                        
                        begin
                            z = eval(x)
                        rescue Exception 
                            z = nil
                        end
                        o << [x,z]
                    end
                end
            end
            o.map{|e|e[0]}
        end
                
        
                         
        
        
        
        
        def backref s, a
            catch(:nomatch) do 
                loop do
                    s.rem(/\\(\w)(\d+)(!)?\\/, true, throws: true) #/)
                    case s.remd[1].to_sym
                    when :f
                        sign = ->(n){n}
                    when :l
                        sign = ->(n){0-n}
                    end
                    e = s.remd[3] ? 1 : 0
                    s=s.rar.join((a[sign.call(s.remd[2].to_i)][e].to_s rescue ''))
                end
            end
            s
        end
        
        
        def add_test(sym, &b)
            define_singleton_method(sym, &b)
        end
        
        
    end
    
    
end
sh = Shorthand

x = sh.items(s)

s = "1.116,316,7,23-25,410,4,601,2.107,205,9,16,402,7,*^A-C,-13,508,13,609,702,5,7,801,2-10,3,901,2,3,9,11-19,3.102,5-7,202,4,503,6-9,608,10,1,*A,-2-4,709,10,3"



module Shorthand
    refine String do
        def sh
            Class.new do
                def initialize(s)
                    @s = s
                end
                Shorthand.singleton_methods.each{|m| define_method(m){Shorthand.send(m,@s)}}
            end.new(self)
        end
    end
end

using Shorthand
p s.sh.is #== x
p s.sh.is == x
#s= gets.strip
#p s.sh.is

=begin
class Object
def add_or(b)
self + b rescue b
end
end

a = (1..100).to_a.map do |i|
o = i % 3 == 0 ? 'Crackle' : i
i % 5 == 0 ? o.add_or('Pop') : o
end
p a
=end
puts "\n---------------------------------------------------------------------------------------------\n\n"
x = (1..100).to_a.map do |i|
    o = "#{i}"
    o+=",^Crackle   " if i % 3 == 0
    o+=",*---Pop" if i % 5 == 0
    #o.sh.is[0].strip
end


y = (1..100).to_a.map do |i|
    a = i % 3 != 0
    b = i % 5 != 0
    #"#{i},?1|#{a}?^Crackle   ,?1|#{b}?*---Pop".sh.is[0].strip
end

#puts y
#s = "testing,-er,*(1,2,3),4"

p s.sh.newis

puts "\n---------------------------------------------------------------------------------------------\n\n"


y = "!! _ % 3 != 0!_;&! _ % 5 != 0!_;&_;?1|\\f0\\?Crackle   ;?1|\\f1\\?*---Pop!&(1-100)".sh.newis.map(&:strip)

p y

