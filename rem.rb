#Welcome to rem.rb
#Author: Sam Tell (stell@samtell.com) - 6/2/2020
#rem is short for "remembered but not removed"
#parse through a string
#make matches (rems) of any regexp-like object, and store the matches within the the string instance for later retreival/manipulation, while preserving the string
#avoid cluttering your local environment with variables to hold all the matches

module RemmyMod
    #add a remgetter
    #takes a symbol 'name' and a regexp-like object 'r'
    #adds a new method called 'name' to the Remmable module that retreives the rem of 'r'
    #will be available to all Remmable objects
    def remgetter name, r
        define_method(name){|*a| getrem(r, *a)}
    end
    
    def allremgetter name, r
        define_method(name){|*a| getallrems(r, *a)}
    end
end
        

module Remmable
    extend RemmyMod
    
    #Strings within the scope of the Remmable module should be themselves remmable
    #especially important if self was made Remmable by 'using' the Remmable module in its source scope, i.e. outside the scope of this module
    #(see at the bottom; there is another refinement of String to include Remmable, this time in the module body proper)
    #(the first refinement is wrapped in an anonomous module, so that the next one is a new refinement instance, and Remmable is included in string after all its methods are defined.) 
    #without this, you could not call Remmable mothods on self within this module...
    #(frankly I'm not sure why the first refinement works inside the module but not outside...  I discovered this by accident...
    #(I need to do more research...  lets add a todo)
    #TODO see above
    using (
        Module.new do
            refine String do
                include ::Remmable
            end
        end
    )
    
    #extends self with the Remmable module
    def remextend
        self.extend(Remmable)
    end
    
    
    #all rems retrived so far in this instance
    def rems
        @rems ||= []
    end
    def remss
        rems.map(&:to_s)
    end
    
    #TODO comment
    def rem_history
        @rem_history ||= []
    end
    
    #self with all rems removed
    def remsult
        @remsult ||= self
    end
    
    #TODO comment
    def rar
        @rar ||= [self]
    end
    
    #returns last retrieved rem
    def remd
        rems[-1]
    end
    
    def remmers
        @remmers ||= []
    end

    
    #retreive a new rem from remsult and add it the rems array
    #throws: determines functionality in the case that there is no match
    # true: raise an exception
    # false: adds nil as the new rem; rar and remsult are unchanged
    #ext: extend self with the Remmable module?
    
    #TODO 
    #rems should only match end of string on the last rar!!
    def getrem(r, sult = false, throws: false, ext: false)
        return getsult(r, throws: throws, ext: ext) if sult
        
        remextend if ext
        
        r = Regexp.new(r)
        remmers << r
        
        rar.each{|e| r.match(e) ? (@rar[@rar.index(e)]=[$`,$']) && break : next} #`
        @rar.flatten!
        @remsult = rar.join
        (throw :nomatch if throws) unless $~
        rems << $~
        self
    end
    
    def getsult(r, throws: false, ext: false)
        remextend if ext
        r = Regexp.new(r)
        remmers << r
        if r.match(remsult)
            @rar = [$`, $'] #throws out old rar... TODO maybe save it somewhere?? #`
            @remsult = rar.join
        end
        (throw :nomatch if throws) unless $~
        rems << $~
        self
    end
    
    
    
    alias retrieverem getrem
    alias addrem getrem
    
    #basically an alias of getrem, but extends self with the Remmable module by default
    def rem(r, sult = false, throws: false, ext:true)
        getrem(r, sult, throws: throws, ext: ext)
    end
    
    
    
    #get the nth available rem of a regex-like obj
    #like an array, 0 is the first
    #count back from zero to start at the end, e.g. -1 will be the last
    def nthrem r, n, throws = false, ext=false
        remextend if ext
        #this whole thing is a total bust with a poorly optimized 'r'...
        l = clone.reset_rems.remall(r).rems.length
        n = l+n if n<0
        n = l if n<0
        r = Regexp.new(r)
        i = -1
        catch :match do
            rar.each do |e| 
                j = -1
                #whats going on with this regex??  basically heres whats happening:
                #
                #1. the first match grouping is everything that comes before our real match.  You can't use quantifiers in a lookbehind, so I had to do it with groupings
                #       it starts with a non-greedy .*? that matches right up to our first 'r' match
                #       it then matches 'r', followed by the next .*? to the next 'r'.  it will do this one 'j' times
                #       'j' being the count of how many times we've looped over this particular 'rar' entry.  So first time through will be 0
                #2. this is our match.
                #3. (.*) for the rest of the string
                #
                #so the 2 grouping is our match for this iteration, but it's only our final match if we've had 'n' matches before it
                #'i' keeps track of total matches, including those made on previous 'rar' entries, 
                #so if 'i' checks out against 'n', we are free to pull the rem and throw ourselves out of this mess
                #
                #frankly, I'm not sure about regex optimization...  TODO study regexs
                #also I'm sure there are bugs.  This would be a good opportunity to practice designing tests
                while /(.*?(?:#{r}.*?){#{j+=1}})(#{r})(.*)/i.match(e)
                    if (i+=1) == n
                        @rar[@rar.index(e)]=[$1,$3]
                        throw(:match) 
                    end
                end
            end
        end #if l>0
        @rar.flatten!
        @remsult = rar.join
        (throw :nomatch if throws) unless $~
        
        rems << $2
        self
    end
    
    
    def clone
        s = String.new self
        self.instance_variables.each do |v|
            s.instance_variable_set(v, self.instance_variable_get(v).clone)
        end
        s
    end
    
    
    
    
    #retrieves all available rems of a regexp-like object
    def getallrems r, *a
        catch :nomatch do
            loop{getrem(r, *a, throws: true)}
        end
        
        self
    end
    
    #basically an alias of getallrems, but will extend self w/ the Remmable module
    def remall r, *a
        catch :nomatch do
            loop{rem(r, *a, throws: true)}
        end
        
        self
    end
    
    #TODO comment, rearange methods
    def remfresh
        String.new self
    end
    
    def remfresh! (save: false)
        save ? (rem_history << clone) : (@rem_history = nil)
        @remsult = nil
        @rems = nil
        @rar = nil
        self
    end
    
    def remset
        remfresh!(save: true)
        self
    end
    
    def rerem(n=-1, ext: false, throws: false)
        getrem(remmers[n], ext: ext, throws: throws)
    end
    
    #add 'using Remmable' to include Remmable in String for a given scope
    refine String do
        include Remmable
    end
    
    #protected
    def reset_rems
        @rems = []
        self
    end
    def new_rar
        @rar = @rar.clone
        self
    end
    def new_rems
        @rems = @rems.clone
        self
    end
    
    
end

#same as Remmable but will return a new instance for any method call
#the new instance will hold all the data and the old one will stay fresh
#remember, '.rem' and '.remall' will extend the returned instance with Remmable, so future calls on those will not keep them fresh
#use '.getrem' and '.getallrems' instead 
module FreshRem
    extend RemmyMod
    
    using(
        Module.new do
            refine String do
                include FreshRem
            end
        end
    )
    
    ::Remmable.instance_methods.each do |m|
        define_method(m) do |*a, &b|
            Remmable.instance_method(m).bind(clone).call(*a, &b)
        end
    end
    
    
    #since clone is defined in Remmable as an instance variable, I gotta redefine it here to avoid an infinite loop
    def clone
        s = String.new self
        self.instance_variables.each do |v|
            s.instance_variable_set(v, self.instance_variable_get(v).clone)
        end
        s
    end
    
    refine String do
        using FreshRem
    end
end