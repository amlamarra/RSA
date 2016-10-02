<#
    Purpose: Generating a public & private RSA key using Powershell
    Author: Andrew M. Lamarra
    Created: 7/8/2015
    Last Modified: 8/6/2015

    PowerShell is limited to dealing with at most 64-bit integers.
    As such, this is only a proof of concept. The keys are insecure.
    I used some sample input from this site:
        https://www.cs.utexas.edu/~mitra/honors/soln.html

    I also used this site to help me write this:
        http://davesource.com/Fringe/Fringe/Crypt/RSA/Algorithm.html
#>

[int]$P = Read-Host "Enter P (random prime)"
[int]$Q = Read-Host "Enter Q (random prime)"
# Find the modulus: m = p*q
[uint64]$M = $P * $Q
Write-Host "The modulus (PQ) is: $M"
# Find the totient: φ(m)=(p-1)(q-1) if p & q are prime
[int]$T = ($P-1)*($Q-1)
Write-Host "The totient (φ(m)) is: $T"

# Algorithm to find a value for E
[int[]]$arrayE = 3, 5, 7, 11, 13, 17, 19, 23

[int[]]$ansE = @()

for ($i = 0; $i -lt 8; $i += 1) {
    [int]$x = $T
    [int]$y = $arrayE[$i]
    while ($y -ne 0) {
        [int]$z = $x % $y
        $x = $y
        $y = $z
    }
    # If the GCD is 1, add that value to another array
    if ($x -eq 1) {$script:ansE += $arrayE[$i]}
}
[uint64]$E = Read-Host "Enter E (possibilities: $ansE)"

# Extended Euclidean Algorithm to find D (private key)
[int]$S = 0 # Step number
[uint64]$D0 = 0 # Current value of D
[int]$D1 = 0 # Value of D from 1 step ago
[int]$D2 = 0 # Value of D from 2 steps ago
[int]$Q0 = 0 # Current Quotient
[int]$Q1 = 0 # Quotient from 1 step ago
[int]$Q2 = 0 # Quotient from 2 steps ago
[int]$newT = $T # Totient
[int]$newE = $E # Value of E

DO {
    $Q2 = $Q1
    $Q1 = $Q0
    $D2 = $D1
    $D1 = $D0
    $S += 1

    [int]$R = $newT % $newE
    $Q0 = ($newT - $R) / $newE

    if ($S -eq 3) {$D1 = 1}
    
    # On paper, this would look like D0=(D2-(D1*Q2)) mod T
    # However, % is a remainder operator & not a modulus operator
    # Because of this, it doesn't handle negatives the same way
    $D0 = ((($D2 - ($D1 * $Q2)) % $T) + $T) % $T
    
    $newT = $newE
    $newE = $R
} WHILE ($R -gt 0)

# Perform the operation 1 more time
$Q2 = $Q1
$D2 = $D1
$D1 = $D0
$D0 = ((($D2 - ($D1 * $Q2)) % $T) + $T) % $T

Write-Host "Your private key (D) is: $D0"
Write-Host "Your public key pair (E, PQ) is: ($E, $M)"`n

# NOTE: uint64 can only handle integers up to 18,446,744,073,709,551,615
[uint64]$PT = Read-Host "Enter the plaintext message (must be an integer)"
[uint64]$exp = [math]::Pow($PT, $E)
[uint64]$CT = ($exp % $M)
Write-Host "Your ciphertext message:" $CT
$exp = [math]::Pow($CT, $D0)
$PT = ($exp % $M)
Write-Host "Your decrypted plaintext message:" $PT