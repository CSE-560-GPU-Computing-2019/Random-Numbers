import random
import matplotlib.pyplot as plt

inputAlgo = "RANDOMNUMBERS_CT_CPU"
input_file = inputAlgo + ".txt"
random_numbers = []
fin = open(input_file)
x = fin.readlines()
for line in x:
    y = line.strip()
    k = int(y)
    random_numbers.append(k)

maxVal = max(random_numbers)
for j in range(len(random_numbers)):
    random_numbers[j] /= float(maxVal)


insidepoints = 0
totalpoints = 0

# iterations = 10000
insideX = []
insideY = []
outsideX = []
outsideY = []

sidelength = 4
radius = sidelength / 2

i = 0
while i < len(random_numbers) - 1:
    # x = random.random() * 2 - 1
    # y = random.random() * 2 - 1
    x = random_numbers[i] * sidelength - 1
    i += 1
    y = random_numbers[i] * sidelength - 1
    
    if (x * x + y * y) <= (sidelength * sidelength):
        insidepoints += 1
        insideX.append(x)
        insideY.append(y)
    
    else:
        outsideX.append(x)
        outsideY.append(y)
    
    totalpoints += 1

ratio = float(insidepoints) / float(totalpoints)

print ("inside points = ", insidepoints)
print ("total points = ", totalpoints)
print ("ratio = ", ratio)
print ("pi = ", ratio * 4)


plt.figure(num=None, figsize=(10, 10), dpi=80, facecolor='w', edgecolor='k')
circle = plt.Circle((0, 0), 1.0)
plt.axis([-2, 2, -2, 2])
plt.gcf().gca().add_artist(circle)
plt.plot(insideX, insideY, 'ro')
plt.plot(outsideX, outsideY, 'bo')
plt.savefig(inputAlgo + "_big.png")
