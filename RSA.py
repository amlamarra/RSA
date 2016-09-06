#!/usr/bin/python3
'''
	Purpose: Generating a public & private RSA key using Python
	Author: Andrew M. Lamarra
	Created: 7/8/2015
	Last Modified: 8/6/2015
	NOTE: I wouldn't use this in any production systems if I were you.
		I'm far from what you might call a "crypto expert"

	I used some sample input from these sites:
		https://www.cs.utexas.edu/~mitra/honors/soln.html
		http://www.cs.virginia.edu/~kam6zx/rsa/a-worked-example/

	I also used this site to help me write this:
		http://davesource.com/Fringe/Fringe/Crypt/RSA/Algorithm.html
'''

P = int(input("Enter P (random prime): "))
Q = int(input("Enter Q (random prime): "))
# Find the modulus: m = p*q
M = P*Q
print("The modulus (P*Q) is: {}".format(M))
# Find the totient: φ(m)=(p-1)(q-1) if p & q are prime
T = (P-1)*(Q-1)
print("The totient (PHI(m)) is: {}".format(T))
# PHI = φ

# Algorithm to find a value for E
arrayE = [3, 5, 7, 11, 13, 17, 19, 23, 65537]

ansE = []

for i in range(8):
	x = T
	y = arrayE[i]
	while (y != 0):
		z = x % y
		x = y
		y = z
	# If the GCD is 1, add that value to another array
	if x == 1:
		ansE.append(arrayE[i])

print("Possible values for E:", *ansE)
E = int(input("Enter E: "))

# Extended Euclidean Algorithm to find D (private key)
S = 0 # Step number
D0 = 0 # Current value of D
D1 = 0 # Value of D from 1 step ago
D2 = 0 # Value of D from 2 steps ago
Q0 = 0 # Current Quotient
Q1 = 0 # Quotient from 1 step ago
Q2 = 0 # Quotient from 2 steps ago
newT = T # Totient
newE = E # Value of E
R = newT % newE

while R > 0:
	Q2 = Q1
	Q1 = Q0
	D2 = D1
	D1 = D0
	S += 1

	R = newT % newE
	Q0 = (newT - R) / newE

	if S == 3:
		D1 = 1
	
	# On paper, this would look like D0=(D2-(D1*Q2)) mod T
	# However, % is a remainder operator & not a modulus operator
	# Because of this, it doesn't handle negatives the same way
	D0 = (((D2 - (D1 * Q2)) % T) + T) % T
	
	newT = newE
	newE = R

# Perform the operation 1 more time
Q2 = Q1
D2 = D1
D1 = D0
D0 = int((((D2 - (D1 * Q2)) % T) + T) % T)

print("Your private key (D) is:", D0)
print("Your public key pair (E, PQ) is: (%i, %i)" % (E, M))

# NOTE: uint64 can only handle integers up to 18,446,744,073,709,551,615
PT = int(input("Enter the plaintext message (must be an integer): "))
CT = (PT**E) % M
print("Your ciphertext message:", CT)
PT = (CT**D0) % M
print("Your decrypted plaintext message:", PT)
