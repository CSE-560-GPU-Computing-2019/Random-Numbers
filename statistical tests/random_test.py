from math import sqrt
import math
from collections import Counter
import numpy
import matplotlib.pyplot as plt


def autocorr(x, t=1):
    co = []
    for i in range(1,t*10,10):
        co.append(numpy.corrcoef(numpy.array([x[:-i], x[i:]]))[1,0])
    return co

def get_uniform():
    a = [random.random() for i in range(100000)]
    z = []
    for i in range(0,len(a),2):
        p , q = box(a[i], a[i+1])
        z.append(p)
        z.append(q)
    b = Counter(z)
    # fig, ax = plt.plot()
    plt.hist(b.keys(), bins = 200)
    plt.ylim(ymax=1)
    plt.show()
    # print(b)

def lol():
    name = 'RANDOMNUMBERS_MT_CPU'
    text = "Mersenne Twister [ CPU ]"
    file = open(name+'.txt', 'r') 
    # This will print every line one by one in the file 
    a = []
    for each in file: 
        a.append(float(each))
    # print(a)
    # a = numpy.array(a)/max(a)
    # b = [random.random() for i in range(10000)]
    # plt.plot(autocorr(a, 1000))
    # plt.plot(autocorr(b, 1000))
    fig = plt.figure()
    plt.hist(a, bins = 200)
    fig.suptitle(text, fontsize=20)
    plt.ylabel('Frequency')
    plt.xlabel('Random Numbers')
    fig.savefig(name+'.png')
    plt.show()


    meh = autocorr(a, 1000)
    fig = plt.figure()
    a = max(meh)
    plt.plot([i for i in range(1,1000*10,10)], meh)
    plt.axhline(y=a, color='r', linestyle='--')
    fig.suptitle(text+"- Autocorrelation", fontsize=20)
    plt.ylabel('Autocorrelation Coeff')
    plt.xlabel('Time difference')
    fig.savefig(name+' autocorr.png')
    plt.show()

lol()