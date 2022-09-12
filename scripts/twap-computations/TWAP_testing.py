class TWAPBound:
    #m_margin = maintenance margin stated as 100% as 1:1 margin
    #twap_t = twap time in minutes (adjusted to seconds in class for calculations as twaps on EVM chains are granular to 1 second)
    #drop_t = drop time in minutes (adjusted to seconds)
    #min_step = the amount added to the drop % per minute to determine how much the value can decrease per minute given the drop time and twap time
    def __init__(self, m_margin, twap_t, drop_t, min_step):
        self.m_margin = m_margin
        self.twap_t = twap_t
        self.drop_t = drop_t
        self.new_plots = drop_t*60
        self.max_difference = (m_margin-100)/m_margin-0.05
        self.price_sequence = [1]*self.twap_t*60
        self.twap_price = 1
        self.min_step = min_step/60
        self.drop_rate = 0

    def compute_twap(self):
        self.twap_price = sum(self.price_sequence[len(self.price_sequence)-self.twap_t*60:])/(self.twap_t*60)

    def next_step(self, drop_rate):
        self.price_sequence.append(self.price_sequence[-1]*(1-drop_rate))
        self.compute_twap()

    def check_difference(self):
        return abs(self.twap_price-self.price_sequence[-1]) < self.max_difference

    def is_drop_rate_valid(self):
        for n in range(self.new_plots):
            self.compute_twap()
            self.check_difference()
            self.next_step(self.drop_rate)
            if self.check_difference() == False:
                return False
        return True

    def reset(self):
        self.new_plots = self.drop_t*60
        self.price_sequence = [1]*self.twap_t*60
        self.twap_price = 1

    def get_max_allowable_loss(self):
        continues = True
        while continues:
            if self.is_drop_rate_valid():
                print((1-((1-self.drop_rate)**60)**self.drop_t)*100)
                self.drop_rate += self.min_step
                self.reset()
            else:
                continues = False
        return (1-((1-self.drop_rate)**60)**self.drop_t)*100

#110% maintenance margin
#60 minutes TWAP
#20 minutes of drop time
#minimum step of 0.00001%
twap_bound = TWAPBound(110, 60, 20, 0.00001)

#value displayed is max allowable loss in % value
print(twap_bound.get_max_allowable_loss())
            

    

    
