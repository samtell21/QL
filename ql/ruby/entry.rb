require '~/QL/rem'
using FreshRem
module QL
    
    class Entry
        @@sym = ['\*', '\-', '\+', '\&', '\^', '\`']

        def initialize s = nil
            p blocks(s)
        end
        
        #private
        
        #TODO
        def parse s
            m =  @@sym.join('|')
            mb = /^(#{m})/
            
            fun = [] 
            body = []
            blocks(s).each do |e|
                case e
                when String
                end
            end
            
            
            ["fuunction", "body"]
        end
        
        def blocks s
            s = "[\""+s+"\"]"
            eval(s.gsub(/(.)(?<!\\)</, '",["\\1","').gsub(/(?<!\\)>/, '"],"'))
            
            
        end
        
    end
end


QL::Entry.new("!<test?<bigger test>>?<test>*&body")
