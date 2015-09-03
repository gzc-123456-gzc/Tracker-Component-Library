function FibNum=nthFibonacciNumber(n)
%%NTHFIBONACCINUMBER  Find the nth number in the Fibonacci series using a
%                     non-recursive formula. The series is 0, 1, 1, 2, 3,
%                     5, 8, 13... where the next number is the sum of the
%                     previous two numbers, starting with 0 for n=0 and 1
%                     for n=1.
%
%INPUTS: n  A scalar or matrix of values at which one wishes to find the
%           corresponding Fibonacci number. Note that n>=0.
%
%OUTPUTS: FibNum The Fibonacci number corresponding to n.
%
%The explicit formula for the nth Fibonacci number is taken from Chapter
%3.4.3 of 
%B. R. Preiss, Data Structures and Algorithms with Object-Oriented Design
%Patterns in C++. New York, NY: John Wiley & Sons, Inc., 1999.
%
%April 2014 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(~all(n>=0))
   error('n must be non-negative'); 
end

sqrt5=sqrt(5);
phi=(1+sqrt5)/2;
phiHat=(1-sqrt(5))/2;

%The round command rounds the result to the nearest integer to handle
%possible finite precision issues.
FibNum=round((phi.^n-phiHat.^n)./sqrt5);
end

%LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.
