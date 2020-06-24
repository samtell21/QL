module Schmutils
    
    #removes @ from a symbol
    #great for setting up attr_accessors given symbol for an instance variable
    def self.noat sym
        sym.to_s.gsub(/\A@/,'').to_sym
    end
    
    #recursively remove all matches on regex 'r' from array entries, hash values, or strings
    def self.remove r, s
        case s
        when String
            s.remall(r).remsult
        when Hash
            s.map{|k,v| [k, remove(r, v)]}.to_h
        when Array
            s.map{|e| remove r, e}
        else
            nil
        end
    end
end
