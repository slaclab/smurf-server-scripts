from epics import PV
import time

fixedRates = ['15kHz','12kHz','10kHz','8kHz','6kHz','5kHz','4kHz', '3kHz', '2kHz', '1kHz']
acRates    = ['60Hz','30Hz','10Hz','5Hz','1Hz','0.5Hz']
f = None

class Instruction(object):

    def __init__(self, args):
        self.args = args

    def encoding(self):
        args = [0]*7
        args[0] = len(self.args)-1
        args[1:len(self.args)+1] = self.args
        return args

class FixedRateSync(Instruction):

    opcode = 0

    def __init__(self, marker, occ):
        super(FixedRateSync, self).__init__( (self.opcode, marker, occ) )

    def print_(self):
        return 'FixedRateSync(%s) # occ(%d)'%(fixedRates[self.args[1]],self.args[2])
    

class ACRateSync(Instruction):

    opcode = 1

    def __init__(self, timeslotm, marker, occ):
        super(ACRateSync, self).__init__( (self.opcode, timeslotm, marker, occ) )

    def print_(self):
        return 'ACRateSync(%s/0x%x) # occ(%d)'%(acRates[self.args[2]],self.args[1],self.args[3])
    

class Branch(Instruction):

    opcode = 2

    def __init__(self, args):
        super(Branch, self).__init__(args)

    @classmethod
    def unconditional(cls, line):
        return cls((cls.opcode, line))

    @classmethod
    def conditional(cls, line, counter, value):
        return cls((cls.opcode, line, counter, value))

    def print_(self):
        if len(self.args)==2:
            return 'Branch unconditional to line %d'%self.args[1]
        else:
            return 'Branch to line %d until ctr%d=%d'%(self.args[1:])
    
class BeamRequest(Instruction):

    opcode = 4
    
    def __init__(self, charge):
        super(BeamRequest, self).__init__((self.opcode, charge))

    def print_(self):
        return 'BeamRequest charge %d'%self.args[1]


class ControlRequest(Instruction):

    opcode = 5
    
    def __init__(self, word):
        super(ControlRequest, self).__init__((self.opcode, word))

    def print_(self):
        return ('ControlRequest word 0x%x'%self.args[1]) + " ({0:b})".format(self.args[1]) 

class SimPv:
    def __init__(self, name):
        self.name = name

    def get(self):
        pass

    def put(self, value):
        f.write('caput %s '%self.name,value)

class SeqUser:
    def __init__(self, base, index, file=''):
        global f
        self.index   = index

        prefix = base+'%02d'%index
        if len(file):
            f = open(file,'w')
            self.ninstr  = SimPv(prefix+':INSTRCNT')
            self.desc    = SimPv(prefix+':DESCINSTRS')
            self.instr   = SimPv(prefix+':INSTRS')
            self.idxseq  = SimPv(prefix+':SEQ00IDX')
            self.seqname = SimPv(prefix+':SEQ00DESC')
            self.idxseqr = SimPv(prefix+':RMVIDX')
            self.seqr    = SimPv(prefix+':RMVSEQ')
            self.insert  = SimPv(prefix+':INS')
            self.idxrun  = SimPv(prefix+':RUNIDX')
            self.start   = SimPv(prefix+':SCHEDRESET')
            self.reset   = SimPv(prefix+':FORCERESET')
        else:
            self.ninstr  = PV(prefix+':INSTRCNT')
            self.desc    = PV(prefix+':DESCINSTRS')
            self.instr   = PV(prefix+':INSTRS')
            self.idxseq  = PV(prefix+':SEQ00IDX')
            self.seqname = PV(prefix+':SEQ00DESC')
            self.idxseqr = PV(prefix+':RMVIDX')
            self.seqr    = PV(prefix+':RMVSEQ')
            self.insert  = PV(prefix+':INS')
            self.idxrun  = PV(prefix+':RUNIDX')
            self.start   = PV(prefix+':SCHEDRESET')
            self.reset   = PV(prefix+':FORCERESET')

    def execute(self, title, instrset):
        self.insert.put(0)

        # Remove existing sub sequences
        ridx = -1
        print ('Remove %d'%ridx)
        if ridx < 0:
            idx = self.idxseq.get()
            while (idx>0):
                print ('Removing seq %d'%idx)
                self.idxseqr.put(idx)
                self.seqr.put(1)
                self.seqr.put(0)
                time.sleep(1.0)
                idx = self.idxseq.get()
        elif ridx > 1:
            print ('Removing seq %d'%ridx)
            self.idxseqr.put(ridx)
            self.seqr.put(1)
            self.seqr.put(0)

        self.desc.put(title)

        encoding = [len(instrset)]
        for instr in instrset:
            encoding = encoding + instr.encoding()

        print (encoding)

        self.instr.put( tuple(encoding) )

        time.sleep(1.0)

        ninstr = self.ninstr.get()
        if ninstr != len(instrset):
            print ('Error: ninstr invalid %u (%u)' % (ninstr, len(instrset)))
            return

        print ('Confirmed ninstr %d'%ninstr)

        self.insert.put(1)
        self.insert.put(0)

        #  Get the assigned sequence num
        idx = self.idxseq.get()
        if idx < 2:
            print ('Error: subsequence index  invalid (%u)' % idx)
            return

        print ('Sequence '+self.seqname.get()+' found at index %d'%idx)

        #  self.post(idx,title,ninstr)

        #  Start it
        self.idxrun.put(idx)
        self.start .put(0)
        self.reset .put(1)
        self.reset .put(0)
